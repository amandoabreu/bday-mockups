#!/bin/bash

FILENAME="history.html"

# Generate commit history HTML file
echo "Generating commit history..."

# Create the HTML file
cat > "$FILENAME" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Commit History - Party Management System</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        :root {
            --blue: #3b82f6;
            --green: #10b981;
            --orange: #f59e0b;
            --orange-light: #fbbf24;
        }
    </style>
</head>
<body class="bg-gray-100 min-h-screen p-4">
    <div class="max-w-4xl mx-auto">
        <div class="bg-white rounded-3xl shadow-xl p-6 space-y-6">
            <h1 class="text-2xl font-bold text-center mb-8">Commit History</h1>
            
            <!-- Summary Stats -->
            <div class="grid grid-cols-3 gap-4 mb-8">
                <div class="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-4 text-white text-center">
                    <div class="text-2xl font-bold" id="total-commits">-</div>
                    <div class="text-sm opacity-90">Total Commits</div>
                </div>
                <div class="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-4 text-white text-center">
                    <div class="text-2xl font-bold" id="lines-added">-</div>
                    <div class="text-sm opacity-90">Lines Added</div>
                </div>
                <div class="bg-gradient-to-r from-red-500 to-red-600 rounded-xl p-4 text-white text-center">
                    <div class="text-2xl font-bold" id="lines-removed">-</div>
                    <div class="text-sm opacity-90">Lines Removed</div>
                </div>
            </div>

            <!-- Commit List -->
            <div id="commit-list" class="space-y-4">
                <!-- Commits will be inserted here -->
            </div>
        </div>
    </div>

    <script>
        // Data will be inserted by the script
        const commitData = [
EOF

# Use a temp file to process the log, which is safer.
TMP_JS_DATA=$(mktemp)

# This function will be called to print the collected data for a commit.
function print_commit_data() {
    if [[ -n "$HASH" ]]; then
        # Default to 0 if null
        FILES=${FILES:-0}
        ADDED=${ADDED:-0}
        REMOVED=${REMOVED:-0}
        # Escape single quotes in message for JS
        MESSAGE_ESCAPED=$(echo "$MESSAGE" | sed "s/'/\\\\'/g")
        echo "            { hash: '$HASH', message: '$MESSAGE_ESCAPED', files: $FILES, added: $ADDED, removed: $REMOVED }," >> "$TMP_JS_DATA"
    fi
}

# Read git log line by line
git log --oneline --stat --no-merges | while IFS= read -r line; do
    # If line is a commit hash, it's a new commit. Print the old one and start a new one.
    if [[ $line =~ ^[a-f0-9]{7} ]]; then
        print_commit_data
        HASH=$(echo "$line" | cut -d' ' -f1)
        MESSAGE=$(echo "$line" | cut -d' ' -f2-)
        # Reset stats
        FILES=0
        ADDED=0
        REMOVED=0
    # If line is the summary stat line
    elif [[ $line =~ files?\ changed ]]; then
        FILES=$(echo "$line" | grep -o '[0-9]\+ files\? changed' | grep -o '[0-9]\+' || echo "0")
        ADDED=$(echo "$line" | grep -o '[0-9]\+ insertions\?' | grep -o '[0-9]\+' || echo "0")
        REMOVED=$(echo "$line" | grep -o '[0-9]\+ deletions\?' | grep -o '[0-9]\+' || echo "0")
    fi
done

# Print the last commit's data
print_commit_data

# Remove the trailing comma from the last JSON object
sed -i '' '$s/,$//' "$TMP_JS_DATA"

# Append the generated JS data to the HTML file
cat "$TMP_JS_DATA" >> "$FILENAME"

# Clean up temp file
rm "$TMP_JS_DATA"


# Complete the HTML file
cat >> "$FILENAME" << 'EOF'
        ];

        // Calculate totals
        let totalCommits = commitData.length;
        let totalAdded = commitData.reduce((sum, commit) => sum + (commit.added || 0), 0);
        let totalRemoved = commitData.reduce((sum, commit) => sum + (commit.removed || 0), 0);

        // Populate commit list
        const commitList = document.getElementById('commit-list');
        commitData.forEach(commit => {
            const commitEl = document.createElement('div');
            commitEl.className = 'border rounded-xl p-4 hover:bg-gray-50 transition-colors';
            commitEl.innerHTML = `
                <div class="flex justify-between items-start mb-2">
                    <div class="font-medium text-sm">${commit.message}</div>
                    <div class="text-xs text-gray-500">${commit.hash}</div>
                </div>
                <div class="flex items-center gap-4 text-xs">
                    <span class="text-green-600">+${commit.added || 0} lines</span>
                    <span class="text-red-600">-${commit.removed || 0} lines</span>
                    <span class="text-gray-500">${commit.files || 0} files changed</span>
                </div>
            `;
            commitList.appendChild(commitEl);
        });

        // Update summary stats
        document.getElementById('total-commits').textContent = totalCommits;
        document.getElementById('lines-added').textContent = totalAdded.toLocaleString();
        document.getElementById('lines-removed').textContent = totalRemoved.toLocaleString();
    </script>
</body>
</html>
EOF

echo "✅ $FILENAME generated successfully!"
echo "📊 Open $FILENAME in your browser to view the commit history" 