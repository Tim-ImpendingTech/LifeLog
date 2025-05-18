# Lifelog Fetching Script

## BLUF (Bottom Line Up Front)
This script fetches lifelogs from the Limitless API for a specified date. It logs the process and saves the results to a file. Ensure you have PowerShell installed and replace the API key in the script with your own.

## Detailed Setup Guide

### Prerequisites
- PowerShell installed on your system.
- An API key from Limitless.

### Step-by-Step Instructions

1. **Clone or Download the Repository**
   - Clone the repository or download the `fetch_lifelogs_redacted.ps1` script to your local machine.

2. **Open PowerShell**
   - Open PowerShell on your machine.

3. **Navigate to the Script Directory**
   - Use the `cd` command to navigate to the directory where the script is located.
     ```powershell
     cd path\to\script\directory
     ```

4. **Edit the Script**
   - Open the `fetch_lifelogs_redacted.ps1` file in a text editor.
   - Replace `'YOUR_API_KEY_HERE'` with your actual API key.

5. **Run the Script**
   - Execute the script using the following command:
     ```powershell
     .\fetch_lifelogs_redacted.ps1
     ```
   - Optionally, specify a date to fetch lifelogs for:
     ```powershell
     .\fetch_lifelogs_redacted.ps1 -date 2025-05-14
     ```

6. **Check the Output**
   - The script will create two files in the same directory:
     - `FetchLog_YYYY_MM_DD.txt`: Contains detailed logs of the script execution.
     - `LL_YYYY_MM_DD.txt`: Contains the fetched lifelog data.

### Troubleshooting
- If you encounter a 504 error, the script will retry up to 10 times.
- Ensure your API key is correct and has the necessary permissions.

### Additional Notes
- The script is self-contained and can be run from any directory.
- The log file provides detailed information about each API request and response. 