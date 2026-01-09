$input_data = [Console]::In.ReadToEnd() | ConvertFrom-Json

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

if ($null -ne $input_data.context_window.current_usage) {
    $usage = $input_data.context_window.current_usage
    if ($null -ne $usage.PSObject.Properties['duration_ms'] -and $null -ne $usage.duration_ms) {
        $ms = $usage.duration_ms
    }
}

if ($null -eq $ms -and $null -ne $input_data.PSObject.Properties['duration'] -and $null -ne $input_data.duration) {
    $ms = $input_data.duration
}

if ($null -ne $ms) {
    if ($ms -ge 1000) {
        $sec = [math]::Round($ms / 1000, 1)
        $duration_str = " ⌛ ${sec}s"
    } else {
        $duration_str = " ⌛ ${ms}ms"
    }
}

$status = "${blue}${model_name}${reset} ${reset}@${reset} ${green}${project}${reset} ${context_bar}${duration_str} ${reset}|${reset} ${session_id}"

Write-Host $status
