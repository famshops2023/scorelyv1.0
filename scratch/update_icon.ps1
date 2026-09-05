Add-Type -AssemblyName System.Drawing
$src = "C:\Users\Lenovo\.gemini\antigravity\brain\1e18f762-a5d8-4c8d-8abe-c4406834cd97\media__1788363506248.jpg"
$dest = "c:\Ajay\scorely_1.0\scorely_offline-main\assets\images\scorely_icon.png"
$img = [System.Drawing.Image]::FromFile($src)
$img.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
Write-Host "Updated scorely_icon.png successfully"
