# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check if WebView2 is installed
if (-not [Microsoft.Web.WebView2.WinForms.WebView2]) {
    Write-Host "WebView2 is not installed. Please install the WebView2 SDK."
    exit
}

# Initialize Global Variables
$defaultHomePage = "https://www.google.com"
$theme = "light"
$privacyMode = $false
$downloads = New-Object System.Collections.ArrayList
$history = New-Object System.Collections.ArrayList
$userProfiles = New-Object System.Collections.Generic.Dictionary[string, [System.Collections.ArrayList]]

# Initialize Main Form
$form = New-Object Windows.Forms.Form
$form.Text = "My Enhanced Browser"
$form.Width = 1024
$form.Height = 768

# Initialize Tab Control
$tabControl = New-Object Windows.Forms.TabControl
$tabControl.Dock = 'Fill'
$form.Controls.Add($tabControl)

# Function to create a new tab
function New-Tab($url) {
    $tabPage = New-Object Windows.Forms.TabPage
    $tabPage.Text = "New Tab"

    $webView = New-Object Microsoft.Web.WebView2.WinForms.WebView2
    $webView.Dock = 'Fill'
    $tabPage.Controls.Add($webView)

    $tabControl.TabPages.Add($tabPage)

    # Initialize WebView2 environment
    $webView.EnsureCoreWebView2Async($null)

    # Handle navigation
    if ($url -and $url -ne "") {
        $webView.Source = $url
    } else {
        $webView.Source = $defaultHomePage
    }

    $tabControl.SelectedTab = $tabPage

    # Add event for navigation completion
    $webView.add_NavigationCompleted({
        param($sender, $args)
        if ($args.IsSuccess) {
            $history.Add($args.Uri.ToString())
            $addressBar.Text = $args.Uri.ToString()
            $tabPage.Text = $webView.CoreWebView2.DocumentTitle
        } else {
            [System.Windows.Forms.MessageBox]::Show("Navigation failed: $($args.WebErrorStatus)")
        }
    })

    # Add event for source changed
    $webView.add_SourceChanged({
        param($sender, $args)
        $addressBar.Text = $webView.Source.ToString()
    })
}

# Initialize the first tab
New-Tab $defaultHomePage

# Address Bar
$addressBar = New-Object Windows.Forms.TextBox
$addressBar.Dock = 'Top'
$addressBar.Height = 30
$form.Controls.Add($addressBar)

# Navigate on Enter
$addressBar.Add_KeyDown({
    param($sender, $eventArgs)
    if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $url = $addressBar.Text
        if (-not $url.StartsWith("http")) {
            $url = "https://$url"
        }
        $tabControl.SelectedTab.Controls[0].CoreWebView2.Navigate($url)
    }
})

# Toolbar
$toolbar = New-Object Windows.Forms.Panel
$toolbar.Dock = 'Top'
$toolbar.Height = 40
$form.Controls.Add($toolbar)

# Back Button
$backButton = New-Object Windows.Forms.Button
$backButton.Text = "Back"
$backButton.Width = 50
$backButton.Height = 30
$backButton.Add_Click({
    $webView = $tabControl.SelectedTab.Controls[0]
    if ($webView.CoreWebView2.CanGoBack) {
        $webView.CoreWebView2.GoBack()
    }
})
$toolbar.Controls.Add($backButton)

# Forward Button
$forwardButton = New-Object Windows.Forms.Button
$forwardButton.Text = "Forward"
$forwardButton.Width = 50
$forwardButton.Height = 30
$forwardButton.Add_Click({
    $webView = $tabControl.SelectedTab.Controls[0]
    if ($webView.CoreWebView2.CanGoForward) {
        $webView.CoreWebView2.GoForward()
    }
})
$toolbar.Controls.Add($forwardButton)

# Refresh Button
$refreshButton = New-Object Windows.Forms.Button
$refreshButton.Text = "Refresh"
$refreshButton.Width = 50
$refreshButton.Height = 30
$refreshButton.Add_Click({
    $webView = $tabControl.SelectedTab.Controls[0]
    $webView.CoreWebView2.Reload()
})
$toolbar.Controls.Add($refreshButton)

# New Tab Button
$newTabButton = New-Object Windows.Forms.Button
$newTabButton.Text = "New Tab"
$newTabButton.Width = 70
$newTabButton.Height = 30
$newTabButton.Add_Click({
    New-Tab $defaultHomePage
})
$toolbar.Controls.Add($newTabButton)

# Show the main form
$form.ShowDialog()