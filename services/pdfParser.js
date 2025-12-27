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

    // Try SBI format first (check for specific SBI headers and patterns)
    // Note: Headers might be split across lines, so check for key patterns
    const isSBI =
      (text.includes("Account Statement") ||
        text.includes("ACCOUNT STATEMENT")) &&
      (text.includes("Txn Date") ||
        text.includes("TXN DATE") ||
        (text.includes("Txn Date Value") &&
          text.includes("Date Description")) ||
        text.includes("IFS Code :SBIN") || // SBI IFS code pattern
        text.includes("State Bank of India") ||
        text.includes("SBI"));

    if (isSBI) {
      console.log("✅ Detected SBI bank statement format");
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
 * Extract transactions from SBI Bank statement format - FIXED VERSION
 *
 * This parser handles:
 * 1. Dates and amounts on different lines
 * 2. Dates split across multiple lines (e.g., "15 Apr" on one line, "2024" on next)
 * 3. Amounts on the same line as description
 * 4. Various transfer patterns: "TO TRANSFER", "TRANSFER TO", "transfered", "transferto"
 *
 * Format: Txn Date | Value Date | Description | Ref No. | Debit | Credit | Balance
 */
function extractSBITransactions(text) {
  const transactions = [];
  const lines = text.split("\n");

  console.log("🔍 Scanning for SBI format transactions...");
  console.log(`📄 Total lines: ${lines.length}\n`);

  // Patterns
  const fullDatePattern =
    /^(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{4})/i;
  const partialDatePattern =
    /^(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))$/i;
  const yearPattern = /^(\d{4})\s*$/;
  const amountPattern = /(\d{1,3}(?:,\d{2,3})*\.\d{2})/g;

  let i = 0;
  let transactionCount = 0;

  while (i < lines.length) {
    const line = lines[i].trim();

    // Check for full date on one line or partial date
    const fullDateMatch = line.match(fullDatePattern);
    const partialDateMatch = !fullDateMatch
      ? line.match(partialDatePattern)
      : null;

    let transactionDate = null;
    const startIndex = i;

    if (fullDateMatch) {
      // Full date on one line
      transactionDate = fullDateMatch[1];
    } else if (partialDateMatch) {
      // Partial date - check if next line has year
      const partialDate = partialDateMatch[1];

      if (i + 1 < lines.length) {
        const nextLine = lines[i + 1].trim();
        const yearMatch = nextLine.match(yearPattern);
        if (yearMatch) {
          const year = yearMatch[1];
          transactionDate = `${partialDate} ${year}`;
          i++; // Skip the year line
        }
      }
    }

    if (transactionDate) {
      // Skip header rows
      if (
        line.includes("Debit") &&
        line.includes("Credit") &&
        line.includes("Balance")
      ) {
        i++;
        continue;
      }

      transactionCount++;
      console.log(`\n${"=".repeat(80)}`);
      console.log(`🔍 Transaction #${transactionCount} at line ${startIndex}`);
      console.log(`📅 Date: ${transactionDate}`);

      // Collect description and look for amounts in next ~15 lines
      const descriptionLines = [];
      let amounts = [];
      let amountLineNum = null;

      for (let j = i + 1; j < Math.min(i + 15, lines.length); j++) {
        const nextLine = lines[j].trim();

        // Stop if we hit another transaction date
        if (nextLine.match(fullDatePattern) && !nextLine.includes("Txn Date")) {
          break;
        }
        if (nextLine.match(partialDatePattern)) {
          break;
        }

        // Check for amounts
        const matches = nextLine.match(amountPattern);
        if (matches && matches.length > 0) {
          const validAmounts = matches
            .map((a) => parseFloat(a.replace(/,/g, "")))
            .filter((a) => a >= 1.0); // Filter out small amounts

          if (validAmounts.length > 0 && amounts.length === 0) {
            amounts = validAmounts;
            amountLineNum = j;
            console.log(
              `💰 Amounts found on line ${j}: ${amounts
                .map((a) => `₹${a.toFixed(2)}`)
                .join(", ")}`
            );
            descriptionLines.push(nextLine);
            break;
          }
        }

        // Add to description
        if (nextLine && !nextLine.includes("Txn Date")) {
          descriptionLines.push(nextLine);
        }
      }

      // Build description
      let description = descriptionLines.join(" ");

      // Remove amounts from description
      amounts.forEach((amt) => {
        const amtFormatted = amt.toLocaleString("en-IN", {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        });
        description = description.replace(amtFormatted, "");
      });

      description = description.replace(/\s+/g, " ").trim();

      console.log(`📝 Description: ${description.substring(0, 80)}`);

      if (amounts.length === 0) {
        console.log("❌ No amounts found, skipping");
        i++;
        continue;
      }

      console.log(
        `✅ Amounts: ${amounts.map((a) => `₹${a.toFixed(2)}`).join(", ")}`
      );

      // Determine transaction type - FIXED LOGIC
      const lowerDesc = description.toLowerCase();

      const isDebit =
        lowerDesc.includes("to transfer") ||
        lowerDesc.includes("transfer to") || // FIXED: Catches "TRANSFER TO" pattern
        lowerDesc.includes("transfered") || // FIXED: Catches typo "transfered"
        lowerDesc.includes("transferto") || // FIXED: Catches "transferto" (no space)
        lowerDesc.includes("transaction comm") || // FIXED: Transaction commission
        lowerDesc.includes("forex txn-commission") ||
        lowerDesc.includes("forex txn-service") ||
        lowerDesc.includes("charges");

      const isCredit =
        lowerDesc.includes("by transfer") ||
        lowerDesc.startsWith("by ") ||
        lowerDesc.includes("deposit");

      console.log(
        `🏷️  Type: ${isDebit ? "DEBIT" : isCredit ? "CREDIT" : "UNKNOWN"}`
      );

      // Extract debit amount
      let debitAmount = 0;

      if (amounts.length >= 2) {
        // Two or more amounts: first is transaction, last is balance
        if (isDebit) {
          debitAmount = amounts[0];
          console.log(`✅ WITHDRAWAL: ₹${debitAmount.toFixed(2)}`);
        } else if (isCredit) {
          console.log(`⏭️  CREDIT (skipping): ₹${amounts[0].toFixed(2)}`);
        }
      } else if (amounts.length === 1) {
        // Single amount - might be transaction or balance
        if (isDebit) {
          // Check if it's clearly a charge/fee
          if (
            lowerDesc.includes("commission") ||
            lowerDesc.includes("service") ||
            lowerDesc.includes("charge") ||
            lowerDesc.includes("fee")
          ) {
            debitAmount = amounts[0];
            console.log(
              `✅ WITHDRAWAL (fee/charge): ₹${debitAmount.toFixed(2)}`
            );
          }
        }
      }

      // Add to transactions if it's a debit
      if (debitAmount > 0) {
        try {
          const parsedDate = parseSBIDate(transactionDate);

          // Clean up description
          let cleanDesc = description
            .replace(/^TO TRANSFER-?/i, "Transfer to ")
            .replace(/^Forex Txn-/i, "Forex Transaction - ")
            .replace(/\s+/g, " ")
            .trim();

          if (!cleanDesc) cleanDesc = "Withdrawal";

          transactions.push({
            date: parsedDate,
            description: cleanDesc.substring(0, 200),
            amount: debitAmount,
            type: "withdrawal",
          });

          console.log(`✅ Added withdrawal transaction`);
        } catch (e) {
          console.log(
            `❌ Error parsing date "${transactionDate}": ${e.message}`
          );
        }
      }

      // Move to line after amounts
      i = amountLineNum ? amountLineNum + 1 : i + 1;
    } else {
      i++;
    }
  }

  console.log(`\n${"=".repeat(80)}`);
  console.log(`📊 Total withdrawal transactions found: ${transactions.length}`);
  console.log("=".repeat(80));

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
