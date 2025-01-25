#!/bin/bash

# Get list of all installed snap packages
SNAP_PACKAGES=$(snap list | tail -n +2 | awk '{print $1}' | sort -u)

# Function to check if package has multiple revisions
has_multiple_revisions() {
    local package=$1
    local revision_count=$(snap list --all "$package" | tail -n +2 | wc -l)
    [[ $revision_count -gt 1 ]]
}

# Function to show packages that will be removed
show_to_be_removed() {
    local package=$1
    if has_multiple_revisions "$package"; then
        local current_rev=$(snap list "$package" | awk 'NR==2 {print $3}')
        local revisions=$(snap list --all "$package" | awk -v cur="$current_rev" '$3 != cur {print $3}')
        echo "Package: $package"
        echo "Revisions to remove: $revisions"
        echo "-------------------"
    fi
}

# Show all packages and revisions that will be removed
echo "The following snap revisions will be removed:"
echo
for package in $SNAP_PACKAGES; do
    show_to_be_removed "$package"
done

# Prompt for confirmation
read -p "Do you want to proceed with removal? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Remove old revisions
echo "Removing old revisions..."
for package in $SNAP_PACKAGES; do
    if has_multiple_revisions "$package"; then
        current_rev=$(snap list "$package" | awk 'NR==2 {print $3}')
        revisions=$(snap list --all "$package" | awk -v cur="$current_rev" '$3 != cur {print $3}')
    
    for revision in $revisions; do
        echo "Removing $package revision $revision..."
        sudo snap remove "$package" --revision="$revision"
    done
    fi
done

echo "Cleanup completed successfully."