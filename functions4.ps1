# ==============================
# WinTweaks Functions
# ==============================

function Initialize-WinTweaks {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Window]$Xaml,
        [Parameter(Mandatory)]
        $TweaksData
    )



# --- Set Window Icon from Web URL ---
$iconUrl = "https://lorencats.com/favicon.ico"  # replace with your actual URL
try {
    $Xaml.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new($iconUrl, [UriKind]::Absolute))
} catch {
    Write-Warning "Failed to load window icon from $iconUrl"
}

    # --- ASCII Art ---
    $asciiArt = @"
 __      ___    _____                 _       
 \ \    / (_)_ |_   _|_ __ _____ __ _| |__ ___
  \ \/\/ /| | ' \| | \ V  V / -_) _` | / /(_-<
   \_/\_/ |_|_||_|_|  \_/\_/\___\__,_|_\_\/__/
"@

# Gradient colors array
$colors = @( "Cyan", "Green", "Yellow", "Magenta", "White" )

# Print ASCII art with gradient effect
$asciiArtLines = $asciiArt -split "`n"
for ($i = 0; $i -lt $asciiArtLines.Count; $i++) {
    $color = $colors[$i % $colors.Count]
    Write-Host $asciiArtLines[$i] -ForegroundColor $color
    Start-Sleep -Milliseconds 100   # slight delay for animated effect
}

Write-Host "`nWelcome to WinTweaks!" -ForegroundColor Cyan

    # Grab UI elements
    $CategoryCombo = $Xaml.FindName("CategoryCombo")
    $ListBox       = $Xaml.FindName("ListBox")
    $RunButton     = $Xaml.FindName("RunButton")
    $ProgressBar   = $Xaml.FindName("ProgressBar")
    $ProgressText  = $Xaml.FindName("ProgressText")

    # --- Refresh List function ---
    function Refresh-List {
        $selectedCategory = $CategoryCombo.SelectedItem
        $ListBox.Items.Clear()
        $items = if ($selectedCategory -eq "All") { $TweaksData.Tweaks } else { $TweaksData.Tweaks | Where-Object { $_.Category -eq $selectedCategory } }
        foreach ($tweak in $items) { $ListBox.Items.Add($tweak.Name) | Out-Null }

        # Reset progress
        $ProgressBar.Value = 0
        $ProgressText.Text = ""
    }

    # --- Populate categories ---
    $allCategories = $TweaksData.Tweaks | Select-Object -ExpandProperty Category -Unique
    $CategoryCombo.Items.Clear()
    $CategoryCombo.Items.Add("All") | Out-Null
    foreach ($cat in $allCategories) { $CategoryCombo.Items.Add($cat) | Out-Null }
    $CategoryCombo.SelectedIndex = 0

    # --- Refresh List on startup ---
    Refresh-List

    # --- Reset progress on selection change ---
    $ListBox.Add_SelectionChanged({
        $ProgressBar.Value = 0
        $ProgressText.Text = ""
    })

    # --- Refresh list when category changes ---
    $CategoryCombo.Add_SelectionChanged({ Refresh-List })

    # --- Apply Tweaks ---
    function Apply-Tweaks {
        $selectedTweaks = $ListBox.SelectedItems
        if ($selectedTweaks.Count -eq 0) {
            $ProgressBar.Value = 0
            $ProgressText.Text = "Select tweaks to run."
            return
        }

        $total = $selectedTweaks.Count
        $counter = 0
        $RunButton.IsEnabled = $false

        foreach ($selectedName in $selectedTweaks) {
            $counter++
            $tweak = $TweaksData.Tweaks | Where-Object { $_.Name -eq $selectedName }
            if (-not $tweak) { continue }

            # Update progress
            $ProgressBar.Value = ($counter / $total) * 100
            $ProgressText.Text = "Applying: $($tweak.Name)..."
            [System.Windows.Forms.Application]::DoEvents()
         switch ($tweak.Type) {
    "Winget" { 
        Start-Process "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe" `
            -ArgumentList 'install','--id='+$tweak.Id,'--exact','--silent','--accept-package-agreements','--accept-source-agreements' `
            -Wait -NoNewWindow
    }
    default  { Invoke-Expression $tweak.Command }
}
        }

        $ProgressBar.Value = 100
        $ProgressText.Text = "All selected tweaks applied."
        $RunButton.IsEnabled = $true
    }

    $RunButton.Add_Click({ Apply-Tweaks })



    # --- Find the Undo button in the UI ---
$UndoButton = $Xaml.FindName("UndoButton")

# --- Wire up the Undo button ---
$UndoButton.Add_Click({
    foreach ($selectedName in $ListBox.SelectedItems) {
        $tweak = $TweaksData.Tweaks | Where-Object { $_.Name -eq $selectedName }
        if ($tweak -and $tweak.UndoCommand) {
            try {
                Invoke-Expression $tweak.UndoCommand
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to undo tweak: $($tweak.Name)`n$($_.Exception.Message)", "Undo Error", "OK", "Error")
            }
        }
    }

    # Reset progress bar and text
    $ProgressBar.Value = 0
    $ProgressText.Text = "Tweaks undone!"
})







    # --- Copyright ---
    $OriginalContent = $Xaml.Content
    $RootGrid = New-Object System.Windows.Controls.Grid
    $Xaml.Content = $null
    $RootGrid.Children.Add($OriginalContent) | Out-Null
    $Xaml.Content = $RootGrid

    $Copyright = New-Object System.Windows.Controls.TextBlock
    $copyrightSymbol = [char]0x00A9
    $Copyright.Text = "$copyrightSymbol $([DateTime]::Now.Year) WinTweaks"
    $Copyright.FontSize = 15 
    $Copyright.Foreground = [System.Windows.Media.Brushes]::Gray
    $Copyright.HorizontalAlignment = "Left"
    $Copyright.VerticalAlignment = "Bottom"
    $Copyright.Margin = [System.Windows.Thickness]::new(10)
    $Copyright.IsHitTestVisible = $false
    [System.Windows.Controls.Panel]::SetZIndex($Copyright, 999)
    $RootGrid.Children.Add($Copyright) | Out-Null

    # --- Show Window ---
    $Xaml.ShowDialog() | Out-Null

    Write-Host "Goodbye from WinTweaks!" -ForegroundColor Cyan
}

