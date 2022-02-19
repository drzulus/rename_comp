Add-Type -assembly System.Windows.Forms
Import-Module ActiveDirectory

Function OnLoad()
{
 $global:comps = Get-ADComputer -Filter * -Properties Name,OperatingSystem
 $listbox1.Items.Clear()
 foreach ($Item in $global:comps)
  {
   $listbox1.Items.Add($Item.Name)
  }
 $textbox2.Text = ""
}

Function listbox1_SelectedIndexChanged()
{
 $textbox1.Text = $listbox1.SelectedItem
 $textbox2.Text = $listbox1.SelectedItem
 $label2.Text = ($global:comps | Where-Object {$_.Name -like $listbox1.SelectedItem}).OperatingSystem
}

Function button1_Click()
{
 $newName = $textbox2.Text
 $oldName = $textbox1.Text
 $user = Get-WMIObject -class Win32_ComputerSystem | Select username
 $cred = Get-Credential $user.username
 $Computer = Get-WmiObject Win32_ComputerSystem -ComputerName $oldName
 if ($Computer)
 {
  $r = $Computer.Rename($newName, $cred.GetNetworkCredential().Password, $cred.UserName)
  if ($r.ReturnValue -eq "1326")
  {[System.Windows.Forms.MessageBox]::Show("Неправильное имя пользователя или пароль.", "Ошибка")}
  elseif ($r.ReturnValue -eq "2221")
  {[System.Windows.Forms.MessageBox]::Show("Компьютер не найден.", "Ошибка")}
  elseif ($r.ReturnValue -eq "0")
  {$OUTPUT = [System.Windows.Forms.MessageBox]::Show($oldName + " переименован в " + $newName + ". Перезагрузить удаленный компьютер сейчас?", "Готово!", 4)
  if ($OUTPUT -eq "YES" ) {Restart-Computer -ComputerName $Computer.Name -Force}
  $textbox1.Text = ""
  OnLoad
  }
  else {[System.Windows.Forms.MessageBox]::Show("Номер ошибки: " + $r.ReturnValue, "Ошибка")}
 }
 else {
  [System.Windows.Forms.MessageBox]::Show("Невозможно подключиться к " + $oldName, "Ошибка")
 }
}

Function textbox1_KeyUp()
{
 $listbox1.Items.Clear()
 $filtered_comps = $global:comps | Where-Object {$_.Name -like $textbox1.Text + '*'}
 foreach ($Item in $filtered_comps)
 {
  $listbox1.Items.Add($Item.Name)
 }
}

$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "Переименование ПК в домене"
$MainForm.Width = 360
$MainForm.Height = 260
$MainForm.StartPosition = "CenterScreen"
$MainForm.AutoSize = $false

$textbox1 = New-Object System.Windows.Forms.TextBox
$textbox1.Location  = New-Object System.Drawing.Point(0,0)
$textbox1.Width = 120
$textbox1.Height = 20
$textbox1.Text = ''
$textbox1.Add_KeyUp({textbox1_KeyUp})
$MainForm.Controls.Add($textbox1)

$label1 = New-Object System.Windows.Forms.Label
$label1.Text = " -----------------------> "
$label1.Location = New-Object System.Drawing.Point(120,0)
$label1.Width = 105
$label1.Height = 20
$MainForm.Controls.Add($label1)

$textbox2 = New-Object System.Windows.Forms.TextBox
$textbox2.Location  = New-Object System.Drawing.Point(225,0)
$textbox2.Width = 120
$textbox2.Height = 20
$textbox2.Text = ''
$MainForm.Controls.Add($textbox2)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = ""
$label2.Location = New-Object System.Drawing.Point(0,20)
$label2.Width = 165
$label2.Height = 30
$MainForm.Controls.Add($label2)

$button1 = New-Object System.Windows.Forms.Button
$button1.Text = 'Переименовать'
$button1.Location = New-Object System.Drawing.Point(165,30)
$button1.Width = 180
$button1.Height = 20
$button1.Add_Click({button1_Click})
$MainForm.Controls.Add($button1)

$listbox1 = New-Object System.Windows.Forms.ListBox
$listbox1.Location  = New-Object System.Drawing.Point(0,60)
$listbox1.Width = 345
$listbox1.Height = 200
$listbox1.Add_Click({listbox1_SelectedIndexChanged})
$MainForm.Controls.add($listbox1)

OnLoad
$MainForm.ShowDialog()
