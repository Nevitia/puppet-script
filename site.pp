class fileUp {

	file { 'C:\\puppet_files':
    		ensure => 'directory',
  	}
	
	file { 'C:\\puppet_files\\7z1600.exe':
			ensure	=> "directory",
			source	=> "puppet:///modules/shared_files/7z1600.exe",
			recurse	=> "true",
		}

	file { "C:\\puppet_files\\diskt.zip":
			ensure	=> "directory",
			source	=> "puppet:///modules/shared_files/diskt.zip",
			recurse	=> "true",
	}

	
	file { "C:\\puppet_files\\SQLEXPR_x86_RUS.exe":
			ensure	=> "directory",
			source	=> "puppet:///modules/shared_files/SQLEXPR_x86_RUS.exe",
			recurse	=> "true",
	}	


	file { 'C:\\puppet_files\\examinator.sql':
			ensure	=> "directory",
			source	=> "puppet:///modules/shared_files/examinator.sql",
			recurse	=> "true",
	}

}

class sqlInst{

	exec { 'mssql':
		command	=> 'C:\sql2014\SQLEXPR_x86_RUS.exe /Q /ACTION=Install /FEATURES=SQL,SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=user /SQLSVCPASSWORD=YUP0Dh /SQLSYSADMINACCOUNTS=user /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /IACCEPTSQLSERVERLICENSETERMS /TCPENABLED=1',
		creates	=> 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\sqlservr.exe',	
		require => Class["fileUp"]	

	}

	exec { 'open_port':
		command		=> 'C:\Windows\System32\cmd.exe /c netsh firewall set portopening protocol = TCP port = 1433 name = SQLPort mode = ENABLE scope = SUBNET profile = CURRENT',
		subscribe	=> Exec["mssql"],
		refreshonly	=> true,		
	}

	


}

class usDiskSh{

	exec { 'add_user':
		command	=> "C:\\Windows\\System32\\cmd.exe /c net user $shared_folder_user $shared_folder_user /ADD",
		unless	=> "C:\\Windows\\System32\\cmd.exe /c net user $shared_folder_user >nul 2>&1 && (exit 0) || (exit 1)"
	}

	file { 'create_folder_to_share':
		path	=> $folder_to_share,
		ensure	=> 'directory',
		owner	=> $shared_folder_user,
		require	=> Exec["add_user"],
	}	
	
	exec { 'share_folder':
		command	=> "C:\\Windows\\System32\\cmd.exe /c net share share=$folder_to_share",
		unless	=> "C:\Windows\System32\cmd.exe /c if exist \\\\${hostname}\\share (exit 0) else (exit 1)",
		require	=> File['create_folder_to_share'],
	}
	
	exec { 'mount_folder':
		command	=> "C:\Windows\System32\cmd.exe /c net use T: \\\\${hostname}\\share /SAVECRED",
		unless	=> "C:\Windows\System32\cmd.exe /c if exist  T: (exit 0) else (exit 1)",
		require	=> Exec['share_folder'],
	}

}

class zipFilScr{

	package { "7-zip":
     		ensure => installed,
     		source => 'C:\puppet_files\7z1600.exe'
	}
	
	exec { 'extract':
		command	=> "C:\Program Files\7-zip\7z.exe" x C:\temp\diskt.zip -oC:\share -r -y",
		require => Class["usDiskSh"]

	}
	
	exec { 'extract':
		command	=> "sqlcmd -S SQLEXPRESS -i C:\temp\examinator.sql",
		require => Class["sqlInst"]

}

node default {
	
	include fileUp,
	include sqlInst,
	include usDiskSh,
	include zipFilScr

}

