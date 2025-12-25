const { PDFParse } = require("pdf-parse");

/**
 * Parse PDF bank statement and extract withdrawal transactions
 * @param {Buffer} pdfBuffer - PDF file buffer
 * @returns {Promise<Array>} Array of transaction objects
 */
async function parseBankStatement(pdfBuffer) {
  try {
    const pdfParser = new PDFParse({ data: pdfBuffer });
    const textData = await pdfParser.getText();
    const text = textData.text || textData;

    // Log first 1000 chars for debugging
    console.log(
      "Extracted PDF text (first 1000 chars):",
      text.substring(0, 1000)
    );
    console.log("\n=== Starting transaction extraction ===\n");

    // Try SBI format first (check for specific SBI headers)
    if (
      text.includes("Account Statement") &&
      text.includes("Txn Date") &&
      text.includes("Value Date")
    ) {
      console.log("Detected SBI bank statement format");
      const transactions = extractSBITransactions(text);
      console.log(`SBI extraction found: ${transactions.length} transactions`);
      if (transactions.length > 0) {
        return transactions;
      }
    }

    // Try Standard Chartered format (most specific)
    let transactions = extractStandardCharteredTransactions(text);
    console.log(
      `Standard Chartered extraction found: ${transactions.length} transactions`
    );

    // If no transactions found, try generic extraction
    if (transactions.length === 0) {
      console.log("Trying generic extraction...");
      transactions = extractTransactionsGeneric(text);
      console.log(
        `Generic extraction found: ${transactions.length} transactions`
      );
    }

    // If still no transactions, try enhanced extraction
    if (transactions.length === 0) {
      console.log("Trying enhanced extraction...");
      transactions = extractTransactionsEnhanced(text);
      console.log(
        `Enhanced extraction found: ${transactions.length} transactions`
      );
    }

    // If still no transactions, try basic extraction
    if (transactions.length === 0) {
      console.log("Trying basic extraction...");
      transactions = extractTransactions(text);
      console.log(
        `Basic extraction found: ${transactions.length} transactions`
      );
    }

    console.log(`\n=== Total transactions found: ${transactions.length} ===\n`);

    // Log first few transactions for debugging
    if (transactions.length > 0) {
      console.log("Sample transactions:");
      transactions.slice(0, 3).forEach((t, i) => {
        console.log(
          `${i + 1}. Date: ${t.date.toISOString().split("T")[0]}, Amount: ${
            t.amount
          }, Desc: ${t.description.substring(0, 50)}`
        );
      });
    }

    return transactions;
  } catch (error) {
    console.error("Error parsing PDF:", error);
    throw new Error("Failed to parse PDF: " + error.message);
  }
}

/**
 * Extract transactions from SBI Bank statement format
 * Format: Txn Date | Value Date | Description | Ref No. | Debit | Credit | Balance
 */
function extractSBITransactions(text) {
  const transactions = [];
  const lines = text.split("\n");

  console.log("Scanning for SBI format transactions...");

  // SBI date format: "4 Apr 2024" or "30 Apr 2024" (DD Mon YYYY)
  const sbiDatePattern =
    /^(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{4})/i;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    // Check if line starts with a date
    const dateMatch = line.match(sbiDatePattern);
    if (!dateMatch) continue;

    const transactionDate = dateMatch[1];

    // SBI format has two dates at the start, then description, then amounts
    // Example: "4 Apr 2024 4 Apr 2024 TO TRANSFER- INR... 1,180.00 62,780.51"

    // Split line into parts
    const parts = line.split(/\s{2,}/); // Split by 2+ spaces

    // Try to find amounts in the line
    // Amounts can be: 52,350.00 or 1,96,760.96 (Indian number format)
    const amountPattern = /(\d{1,3}(?:,\d{2,3})*\.\d{2})/g;
    const amounts = [];
    let match;

    while ((match = amountPattern.exec(line)) !== null) {
      const amount = parseFloat(match[1].replace(/,/g, ""));
      if (amount > 0 && amount < 100000000) {
        // Reasonable limit
        amounts.push(amount);
      }
    }

    // SBI statements have: Debit, Credit, Balance (last 3 amounts)
    // If 3+ amounts: debit=amounts[-3], credit=amounts[-2], balance=amounts[-1]
    // If 2 amounts: could be debit+balance OR credit+balance
    // If 1 amount: it's the balance only

    if (amounts.length === 0) continue;

    // Extract description - it's between the two dates and before the amounts
    let description = line;
    // Remove dates
    description = description.replace(sbiDatePattern, "").trim();
    description = description.replace(sbiDatePattern, "").trim();
    // Remove all amounts
    amounts.forEach((amt) => {
      const amtStr = amt.toLocaleString("en-IN", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
      description = description.replace(amtStr, "");
    });
    description = description.replace(/\s+/g, " ").trim();

    // Determine if it's a debit (withdrawal) or credit (deposit)
    let debitAmount = 0;
    let creditAmount = 0;

    const lowerLine = line.toLowerCase();
    const lowerDesc = description.toLowerCase();

    // Check keywords to determine transaction type
    const isDebit =
      lowerDesc.includes("to transfer") ||
      lowerDesc.includes("forex txn-commission") ||
      lowerDesc.includes("forex txn-service") ||
      lowerDesc.includes("charges") ||
      lowerDesc.includes("withdrawal");

    const isCredit =
      lowerDesc.includes("by transfer") ||
      lowerDesc.includes("deposit") ||
      lowerDesc.includes("credit");

    // Extract debit amount based on position
    if (amounts.length >= 3) {
      // Standard format: debit, credit, balance
      const possibleDebit = amounts[amounts.length - 3];
      const possibleCredit = amounts[amounts.length - 2];

      // If keyword says debit, use first of last 3
      if (isDebit) {
        debitAmount = possibleDebit;
      } else if (isCredit) {
        creditAmount = possibleCredit;
      } else {
        // Guess based on context - "TO" usually means debit, "BY" means credit
        if (lowerDesc.startsWith("to ") || lowerDesc.includes(" to ")) {
          debitAmount = possibleDebit;
        } else if (lowerDesc.startsWith("by ") || lowerDesc.includes(" by ")) {
          creditAmount = possibleCredit;
        }
      }
    } else if (amounts.length === 2) {
      // Two amounts: likely debit/credit + balance
      if (isDebit) {
        debitAmount = amounts[0];
      } else if (isCredit) {
        creditAmount = amounts[0];
      } else {
        // Default: if "TO", it's debit
        if (lowerDesc.startsWith("to ") || lowerDesc.includes(" to ")) {
          debitAmount = amounts[0];
        }
      }
    }

    // Only process debits (withdrawals)
    if (debitAmount > 0) {
      // Clean up description
      description = description
        .replace(/^TO TRANSFER-?/i, "Transfer to ")
        .replace(/^Forex Txn-/i, "Forex Transaction - ")
        .replace(/\s+/g, " ")
        .trim();

      if (!description) description = "Withdrawal";

      try {
        const parsedDate = parseSBIDate(transactionDate);
        console.log(
          `Found debit: ${
            parsedDate.toISOString().split("T")[0]
          } - ₹${debitAmount.toFixed(2)} - ${description.substring(0, 40)}`
        );

        transactions.push({
          date: parsedDate,
          description: description,
          amount: debitAmount,
          type: "withdrawal",
        });
      } catch (e) {
        console.log(`Error parsing date "${transactionDate}":`, e.message);
      }
    } else if (creditAmount > 0) {
      console.log(
        `Skipping credit: ${description.substring(
          0,
          50
        )}... (₹${creditAmount.toFixed(2)})`
      );
    }
  }

  return transactions;
}

/**
 * Parse SBI date format (DD Mon YYYY or D Mon YYYY)
 * Example: "4 Apr 2024" or "30 Apr 2024"
 */
function parseSBIDate(dateStr) {
  const monthMap = {
    jan: 0,
    feb: 1,
    mar: 2,
    apr: 3,
    may: 4,
    jun: 5,
    jul: 6,
    aug: 7,
    sep: 8,
    oct: 9,
    nov: 10,
    dec: 11,
  };

  const parts = dateStr.trim().toLowerCase().split(/\s+/);
  if (parts.length !== 3) {
    throw new Error("Invalid date format");
  }

  const day = parseInt(parts[0]);
  const month = monthMap[parts[1]];
  const year = parseInt(parts[2]);

  if (month === undefined || isNaN(day) || isNaN(year)) {
    throw new Error("Invalid date components");
  }

  return new Date(year, month, day);
}

/**
 * Extract transactions from Standard Chartered Bank statement format
 * Handles both:
 * 1. Transactions with date line: "DD Mon YY  DD Mon YY"
 * 2. Same-day transactions without date line (use previous date)
 */
function extractStandardCharteredTransactions(text) {
  const transactions = [];
  const lines = text.split("\n");

  // Standard Chartered date format: "17 Jun 19  16 Jun 19" (two dates on same line)
  const scDatePattern =
    /^(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{2})\s+(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{2})/i;

  console.log("Scanning for Standard Chartered format transactions...");

  let lastTransactionDate = null; // Track last date for same-day transactions

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    // Check for SC date pattern
    const dateMatch = line.match(scDatePattern);
    let transactionDate = null;
    let startLine = i;

    if (dateMatch) {
      // This transaction has a date line
      transactionDate = dateMatch[1];
      lastTransactionDate = transactionDate;

      // Skip BALANCE FORWARD
      if (line.toUpperCase().includes("BALANCE FORWARD")) {
        console.log(`Skipping balance forward: ${line.substring(0, 60)}...`);
        continue;
      }

      startLine = i + 1; // Start reading from next line
    } else {
      // Check if this might be a transaction without a date (same-day transaction)
      // These start with keywords like "PURCHASE", "UPI/", "IMPS/", or continue from previous
      const mightBeTransaction = line.match(
        /^(PURCHASE|UPI\/|IMPS\/|ATM|CRADJ|CREDIT)/i
      );

      if (mightBeTransaction && lastTransactionDate) {
        // Use the last transaction date
        transactionDate = lastTransactionDate;
        startLine = i;
      } else {
        // Not a transaction start, skip
        continue;
      }
    }

    if (!transactionDate) continue;

    // Read following lines for description and amounts
    let descLines = [];
    let amountLine = "";
    let foundAmount = false;

    for (let j = startLine; j < Math.min(startLine + 10, lines.length); j++) {
      const nextLine = lines[j].trim();

      // Stop if we hit another date line or empty line followed by date
      if (nextLine.match(scDatePattern)) break;
      if (!nextLine) continue; // Skip empty lines but keep going

      // Check if line has amounts (comma-separated number with decimal)
      const hasAmounts = /\d{1,3}(?:,\d{3})*\.\d{2}/.test(nextLine);

      if (hasAmounts && !foundAmount) {
        amountLine = nextLine;
        foundAmount = true;
        break;
      } else if (!hasAmounts) {
        descLines.push(nextLine);
      }
    }

    if (foundAmount && amountLine) {
      // Extract amounts
      const amounts = [];
      const regex = /(\d{1,3}(?:,\d{3})*\.\d{2})/g;
      let match;
      while ((match = regex.exec(amountLine)) !== null) {
        const amount = parseFloat(match[1].replace(/,/g, ""));
        if (amount > 0 && amount < 1000000) {
          amounts.push(amount);
        }
      }

      if (amounts.length >= 2) {
        const withdrawalAmount = amounts[amounts.length - 2];
        const balance = amounts[amounts.length - 1];

        let description = descLines.join(" ").trim();
        const lowerDesc = description.toLowerCase();

        // Check if credit - be very specific, only exclude clear credits
        const isCredit =
          lowerDesc.includes("credit of interest") ||
          (lowerDesc.includes("neft") &&
            lowerDesc.includes("state bank of india")) || // Incoming NEFT
          lowerDesc.includes("cradj/upi") || // Credit adjustment
          lowerDesc.includes("discount on fuel"); // Fuel discount refund

        // UPI classification - be more inclusive for payments
        const isUPIPayment =
          lowerDesc.includes("upi/") &&
          (lowerDesc.includes("paytm") ||
            lowerDesc.includes("amazon") ||
            lowerDesc.includes("google") ||
            lowerDesc.includes("add-money") ||
            lowerDesc.includes("ixigo") ||
            lowerDesc.includes("airtel") ||
            lowerDesc.includes("billdesk") ||
            lowerDesc.includes("indiaideas") ||
            lowerDesc.includes("payment") ||
            lowerDesc.includes("@")); // UPI handles like paytm@icici

        const isUPIReceipt =
          lowerDesc.includes("upi/") &&
          !isUPIPayment &&
          (lowerDesc.includes("rajaguru") ||
            lowerDesc.includes("dummy name") ||
            (lowerDesc.includes("cr") && lowerDesc.includes("upi")) ||
            /mr\s+[a-z]/.test(lowerDesc) ||
            lowerDesc.includes("lic premium") ||
            lowerDesc.includes("season ticket")); // Receiving money for season ticket

        const isWithdrawal =
          lowerDesc.includes("atm withdrawal") ||
          lowerDesc.includes("purchase") ||
          lowerDesc.includes("imps/p2a") ||
          lowerDesc.includes("charges") ||
          lowerDesc.includes("cgst") ||
          lowerDesc.includes("sgst") ||
          isUPIPayment ||
          (lowerDesc.includes("upi/") && !isUPIReceipt); // Default UPI to payment unless receipt

        if (isCredit || isUPIReceipt) {
          console.log(
            `Skipping credit/receipt: ${description.substring(0, 60)}...`
          );
          continue;
        }

        if (isWithdrawal) {
          description = description
            .replace(/\s+/g, " ")
            .replace(/^PURCHASE\s+/i, "Purchase at ")
            .replace(/^ATM WITHDRAWAL\s+/i, "ATM Withdrawal - ")
            .replace(/^UPI\//i, "UPI Payment - ")
            .replace(/^IMPS\//i, "IMPS - ")
            .trim();

          if (!description) description = "Withdrawal";

          try {
            const parsedDate = parseSCDate(transactionDate);
            console.log(
              `Found transaction: ${
                parsedDate.toISOString().split("T")[0]
              } - ₹${withdrawalAmount} - ${description.substring(0, 40)}`
            );

            transactions.push({
              date: parsedDate,
              description: description,
              amount: withdrawalAmount,
              type: "withdrawal",
            });
          } catch (e) {
            console.log(`Error parsing date "${transactionDate}":`, e.message);
          }
        }
      }
    }
  }

  return transactions;
}

/**
 * Parse Standard Chartered date format (DD Mon YY)
 */
function parseSCDate(dateStr) {
  const monthMap = {
    jan: 0,
    feb: 1,
    mar: 2,
    apr: 3,
    may: 4,
    jun: 5,
    jul: 6,
    aug: 7,
    sep: 8,
    oct: 9,
    nov: 10,
    dec: 11,
  };

  const parts = dateStr.trim().toLowerCase().split(/\s+/);
  if (parts.length !== 3) {
    throw new Error("Invalid date format");
  }

  const day = parseInt(parts[0]);
  const month = monthMap[parts[1]];
  const year = 2000 + parseInt(parts[2]); // Assuming 20xx

  if (month === undefined || isNaN(day) || isNaN(year)) {
    throw new Error("Invalid date components");
  }

  return new Date(year, month, day);
}

/**
 * Extract withdrawal transactions from PDF text (basic method)
 */
function extractTransactions(text) {
  const transactions = [];
  const lines = text.split("\n");

  // Common patterns for bank statements
  const datePattern = /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/;
  const amountPattern = /[₹]?([-]?\d+\.?\d*)/;

  let currentDate = null;
  let currentDescription = "";
  let currentAmount = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const dateMatch = line.match(datePattern);
    if (dateMatch) {
      if (currentDate && currentAmount !== null && currentAmount < 0) {
        transactions.push({
          date: parseDate(currentDate),
          description: currentDescription.trim(),
          amount: Math.abs(currentAmount),
          type: "withdrawal",
        });
      }

      currentDate = dateMatch[1];
      currentDescription = "";
      currentAmount = null;
    }

    const amountMatch = line.match(amountPattern);
    if (amountMatch) {
      const amount = parseFloat(amountMatch[1]);
      if (amount < 0) {
        currentAmount = amount;
      }
    }

    if (currentDate && !dateMatch && !amountMatch) {
      currentDescription += " " + line;
    }
  }

  if (currentDate && currentAmount !== null && currentAmount < 0) {
    transactions.push({
      date: parseDate(currentDate),
      description: currentDescription.trim(),
      amount: Math.abs(currentAmount),
      type: "withdrawal",
    });
  }

  return transactions;
}

/**
 * Generic extraction - handles various formats
 */
function extractTransactionsGeneric(text) {
  const transactions = [];
  const lines = text.split("\n");

  const datePattern = /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/;
  const amountPattern = /\b(\d{1,3}(?:,\d{3})*\.\d{2})\b/g;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line || line.length < 15) continue;

    const dateMatch = line.match(datePattern);
    if (!dateMatch) continue;

    const lowerLine = line.toLowerCase();
    const isWithdrawal =
      lowerLine.includes("withdrawal") ||
      lowerLine.includes("atm") ||
      lowerLine.includes("purchase") ||
      lowerLine.includes("payment") ||
      lowerLine.includes("debit") ||
      lowerLine.includes("upi");

    const isCredit =
      lowerLine.includes("credit") ||
      lowerLine.includes("deposit") ||
      lowerLine.includes("balance forward");

    if (isCredit) continue;

    if (isWithdrawal) {
      const amounts = [];
      let match;
      const regex = /\b(\d{1,3}(?:,\d{3})*\.\d{2})\b/g;
      while ((match = regex.exec(line)) !== null) {
        const amount = parseFloat(match[1].replace(/,/g, ""));
        if (amount > 0 && amount < 1000000) {
          amounts.push(amount);
        }
      }

      if (amounts.length > 0) {
        const amount = amounts[0];
        let description = line
          .replace(dateMatch[0], "")
          .replace(amount.toString(), "")
          .trim();

        try {
          const date = parseDate(dateMatch[1]);
          transactions.push({
            date: date,
            description: description || "Withdrawal",
            amount: amount,
            type: "withdrawal",
          });
        } catch (e) {
          console.log("Error parsing date:", dateMatch[1], e);
        }
      }
    }
  }

  return transactions;
}

/**
 * Enhanced extraction for table-format statements
 */
function extractTransactionsEnhanced(text) {
  const transactions = [];

  const transactionPattern =
    /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\s+(.+?)\s+([₹]?\d+[,\d]*\.?\d*)\s+([₹]?\d+[,\d]*\.?\d*)?/g;

  let match;
  while ((match = transactionPattern.exec(text)) !== null) {
    try {
      const date = parseDate(match[1]);
      const description = match[2].trim();
      const debit = parseFloat(match[3].replace(/[₹, ]/g, "")) || 0;
      const credit = parseFloat((match[4] || "0").replace(/[₹, ]/g, "")) || 0;

      if (debit > 0 && debit < 1000000) {
        transactions.push({
          date: date,
          description: description || "Withdrawal",
          amount: debit,
          type: "withdrawal",
        });
      }
    } catch (e) {
      console.log("Error in enhanced extraction:", e);
    }
  }

  return transactions;
}

/**
 * Parse date string to Date object
 */
function parseDate(dateString) {
  const formats = [
    /(\d{1,2})\/(\d{1,2})\/(\d{4})/, // DD/MM/YYYY
    /(\d{1,2})-(\d{1,2})-(\d{4})/, // DD-MM-YYYY
    /(\d{4})-(\d{1,2})-(\d{1,2})/, // YYYY-MM-DD
  ];

  for (const format of formats) {
    const match = dateString.match(format);
    if (match) {
      if (format === formats[2]) {
        return new Date(
          parseInt(match[1]),
          parseInt(match[2]) - 1,
          parseInt(match[3])
        );
      } else {
        return new Date(
          parseInt(match[3]),
          parseInt(match[2]) - 1,
          parseInt(match[1])
        );
      }
    }
  }

  return new Date(dateString);
}

module.exports = {
  parseBankStatement,
  extractTransactions,
  extractTransactionsEnhanced,
  extractTransactionsGeneric,
  extractStandardCharteredTransactions,
  extractSBITransactions,
};
