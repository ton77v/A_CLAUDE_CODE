# Read JSON from stdin
$input_data = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Extract values
$model_name = $input_data.model.display_name
$current_dir = Split-Path -Leaf $input_data.workspace.current_dir
$output_style = $input_data.output_style.name
$vim_mode = if ($input_data.vim) { $input_data.vim.mode } else { $null }

# Context window percentage
$context_pct = ""
if ($input_data.context_window.current_usage) {
    $usage = $input_data.context_window.current_usage
    $current = $usage.input_tokens + $usage.cache_creation_input_tokens + $usage.cache_read_input_tokens
    $size = $input_data.context_window.context_window_size
    if ($size -gt 0) {
        $pct = [math]::Floor(($current * 100) / $size)
        $context_pct = " | $pct% ctx"
    }
}

# Build status line
$status = "$current_dir | $model_name"
if ($output_style -ne "default") {
    $status += " ($output_style)"
}
if ($vim_mode) {
    $status += " [$vim_mode]"
}
$status += $context_pct

Write-Host $status
