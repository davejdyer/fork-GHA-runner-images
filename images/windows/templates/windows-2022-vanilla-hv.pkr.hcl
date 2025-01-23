variable "iso_url" {
  type = string
}

variable "iso_checksum" {
  type = string
}

variable "pstools_path" {
  type = string
}

variable "switch_name" {
  type    = string
  default = "Default Switch"
}

source "hyperv-iso" "ws2019" {
  boot_command         = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait            = "1s"
  cpus                 = 2
  disk_size            = 61440
  enable_secure_boot   = true
  generation           = 2
  iso_checksum         = var.iso_checksum
  iso_url              = var.iso_url
  memory               = 4096
  secondary_iso_images = ["./autounattend/Autounattend.iso"]  
  shutdown_command     = "C:\\Windows\\System32\\Sysprep\\sysprep.exe /generalize /shutdown /oobe /unattend:C:\\Windows\\Temp\\sysprep.xml"
  switch_name          = var.switch_name
  vm_name              = "ws2019"
  communicator         = "winrm"
  winrm_username       = "Administrator"
  winrm_password       = "Autodeploy1"
  winrm_timeout        = "1h"
}

build {
  sources = ["source.hyperv-iso.ws2019"]

  provisioner "file" {
    source      = "./sysprep/sysprep.xml"
    destination = "C:\\Windows\\Temp\\sysprep.xml"
  }

  provisioner "file" {
    source      = "../shared/Patching/Scripts/"
    destination = "C:\\Users\\Administrator\\Desktop"
  }

  provisioner "file" {
    source      = "../shared/Patching/PSWindowsUpdate"
    destination = "C:\\Program Files\\WindowsPowerShell\\Modules"
  }

  provisioner "powershell" {
    inline = [
      "New-Item C:\\Tools -Type Directory -Force | Out-Null",
      "[Environment]::SetEnvironmentVariable('Path', $ENV:Path + ';C:\\Tools\\PSTools\\', 'Machine')"
    ]
  }

  provisioner "file" {
    source      = var.pstools_path
    destination = "C:\\Tools"
  }

  provisioner "powershell" {
    scripts           = ["./scripts/1.ps1", "./scripts/2.ps1"]
  }

  provisioner "windows-restart" {
    restart_command = "C:\\Users\\Administrator\\Desktop\\Updates.bat"
    restart_timeout = "60m"
  }

  post-processor "vagrant" {
    keep_input_artifact = false
    output              = "ws2019.box"
  }
