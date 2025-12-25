const fs = require("fs");
const path = require("path");

// Import the improved parser
const pdfParser = require("./services/pdfParser");

async function testPDFParser() {
  try {
    // Read the PDF file
    const pdfPath = process.argv[2] || "test_statement.pdf";

    if (!fs.existsSync(pdfPath)) {
      console.error(`Error: PDF file not found at ${pdfPath}`);
      console.log("Usage: node test_pdf_parser.js <path_to_pdf>");
      process.exit(1);
    }

    console.log(`Reading PDF: ${pdfPath}\n`);
    const pdfBuffer = fs.readFileSync(pdfPath);

    console.log("=".repeat(60));
    console.log("TESTING PDF PARSER");
    console.log("=".repeat(60));
    console.log();

    // Parse the PDF
    const transactions = await pdfParser.parseBankStatement(pdfBuffer);

    console.log();
    console.log("=".repeat(60));
    console.log(
      `RESULTS: Found ${transactions.length} withdrawal transactions`
    );
    console.log("=".repeat(60));
    console.log();

    if (transactions.length === 0) {
      console.log("❌ No transactions found!");
      console.log("\nThis could mean:");
      console.log("1. The PDF format is not recognized");
      console.log("2. No withdrawal transactions in the statement");
      console.log("3. The parser needs to be customized for this bank format");
      process.exit(1);
    }

    // Display all transactions
    console.log("All Transactions:\n");
    console.log("-".repeat(100));
    console.log("Date       | Amount     | Description");
    console.log("-".repeat(100));

    let totalAmount = 0;
    transactions.forEach((t, index) => {
      const dateStr = t.date.toISOString().split("T")[0];
      const amountStr = `₹${t.amount.toFixed(2)}`.padEnd(11);
      const descStr = t.description.substring(0, 70);
      console.log(`${dateStr} | ${amountStr} | ${descStr}`);
      totalAmount += t.amount;
    });

    console.log("-".repeat(100));
    console.log();

    // Summary
    console.log("Summary:");
    console.log(`  Total Transactions: ${transactions.length}`);
    console.log(`  Total Amount: ₹${totalAmount.toFixed(2)}`);
    console.log(
      `  Average: ₹${(totalAmount / transactions.length).toFixed(2)}`
    );
    console.log(
      `  Date Range: ${transactions[0].date.toISOString().split("T")[0]} to ${
        transactions[transactions.length - 1].date.toISOString().split("T")[0]
      }`
    );
    console.log();

    // Test roundoff calculation
    console.log("Roundoff Calculation Test (₹10 roundoff):");
    console.log("-".repeat(100));
    console.log("Amount     | Rounded    | Savings");
    console.log("-".repeat(100));

    let totalSavings = 0;
    transactions.slice(0, 5).forEach((t) => {
      const rounded = Math.ceil(t.amount / 10) * 10;
      const savings = rounded - t.amount;
      totalSavings += savings;
      console.log(
        `₹${t.amount.toFixed(2).padEnd(9)} | ₹${rounded
          .toFixed(2)
          .padEnd(9)} | ₹${savings.toFixed(2)}`
      );
    });
    console.log(`... (showing first 5 transactions)`);
    console.log("-".repeat(100));

    // Calculate total savings for all transactions
    totalSavings = 0;
    transactions.forEach((t) => {
      const rounded = Math.ceil(t.amount / 10) * 10;
      totalSavings += rounded - t.amount;
    });

    console.log();
    console.log(
      `✅ Total Potential Savings (₹10 roundoff): ₹${totalSavings.toFixed(2)}`
    );
    console.log();

    // Success
    console.log("=".repeat(60));
    console.log("✅ TEST PASSED - Parser working correctly!");
    console.log("=".repeat(60));
  } catch (error) {
    console.error();
    console.error("=".repeat(60));
    console.error("❌ TEST FAILED");
    console.error("=".repeat(60));
    console.error();
    console.error("Error:", error.message);
    console.error();
    console.error("Stack trace:");
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the test
testPDFParser();
