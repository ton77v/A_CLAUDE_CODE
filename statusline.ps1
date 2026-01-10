[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$input_data = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Debug: Write JSON structure to temp file
$debug_file = "$env:TEMP\claude_statusline_debug.json"
$input_data | ConvertTo-Json -Depth 10 | Out-File -FilePath $debug_file -Encoding utf8

$blue = "$([char]27)[34m"
$green = "$([char]27)[32m"
$cyan = "$([char]27)[36m"
$yellow = "$([char]27)[33m"
$orange = "$([char]27)[38;5;208m"
$red = "$([char]27)[31m"
$reset = "$([char]27)[0m"

$model_name = $input_data.model.display_name
$project = Split-Path -Leaf $input_data.workspace.current_dir
$session_id = $input_data.session_id

$context_bar = ""
$pct = 0
if ($input_data.context_window.current_usage) {
    $usage = $input_data.context_window.current_usage
    $current = $usage.input_tokens + $usage.cache_creation_input_tokens + $usage.cache_read_input_tokens
    $size = $input_data.context_window.context_window_size
    if ($size -gt 0) {
        $pct = [math]::Floor(($current * 100) / $size)
        $bar_length = 10
        $filled = [math]::Floor(($pct * $bar_length) / 100)
        $empty = $bar_length - $filled
        $bar_fill = ("=" * $filled) + (" " * $empty)

        $pct_color = $yellow
        if ($pct -ge 75) {
            $pct_color = $red
        } elseif ($pct -ge 50) {
            $pct_color = $orange
        }

        $context_bar = "${cyan}[${bar_fill}]${reset} ${pct_color}${pct}%${reset}"
    }
}

$duration_str = ""
$ms = $null

# Check all possible duration locations
if ($input_data.PSObject.Properties['duration'] -and $null -ne $input_data.duration) {
    $ms = $input_data.duration
}

if ($null -eq $ms -and $input_data.PSObject.Properties['context_window'] -and $input_data.context_window.PSObject.Properties['current_usage']) {
    $usage = $input_data.context_window.current_usage
    if ($usage.PSObject.Properties['duration_ms'] -and $null -ne $usage.duration_ms) {
        $ms = $usage.duration_ms
    }
}

if ($null -eq $ms -and $input_data.PSObject.Properties['context_window'] -and $input_data.context_window.PSObject.Properties['duration']) {
    $ms = $input_data.context_window.duration
}

if ($null -eq $ms -and $input_data.PSObject.Properties['last_turn_duration']) {
    $ms = $input_data.last_turn_duration
}

if ($null -eq $ms -and $input_data.PSObject.Properties['cost'] -and $input_data.cost.PSObject.Properties['total_duration_ms']) {
    $ms = $input_data.cost.total_duration_ms
}

# Debug: Log which duration source was found
$debug_info = "Duration check: "
if ($null -ne $ms) {
    $debug_info += "Found=$ms"
} else {
    $debug_info += "Not found. Available top-level properties: "
    $debug_info += ($input_data.PSObject.Properties.Name -join ", ")
}
$debug_info | Out-File -FilePath "$env:TEMP\claude_statusline_duration_debug.txt" -Encoding utf8

if ($null -ne $ms) {
    $sec = [math]::Round($ms / 1000, 1)
    if ($sec -ge 60) {
        $min = [math]::Round($sec / 60, 1)
        $duration_str = " ${min} mins"
    } elseif ($ms -ge 1000) {
        $duration_str = " ${sec} secs"
    } else {
        $duration_str = " ${ms} ms"
    }
}

$status = "${blue}${model_name}${reset} ${reset}@${reset} ${green}${project}${reset} ${context_bar}${duration_str} ${yellow}|${reset} ${session_id}"

Write-Host $status
