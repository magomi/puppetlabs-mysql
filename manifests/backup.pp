# Class: mysql::backup
#
# This module handles ...
#
# Parameters:
#   [*backupuser*]     - The name of the mysql backup user.
#   [*backuppassword*] - The password of the mysql backup user.
#   [*backupdir*]      - The target directory of the mysqldump.
#   [*backupcompress*] - Boolean to compress backup with bzip2.
#   [*backuprotate*]   - Number of backups to keep. Default 30
#
# Actions:
#   GRANT SELECT, RELOAD, LOCK TABLES ON *.* TO 'user'@'localhost'
#    IDENTIFIED BY 'password';
#
# Requires:
#   Class['mysql::config']
#
# Sample Usage:
#   class { 'mysql::backup':
#     backupuser     => 'myuser',
#     backuppassword => 'mypassword',
#     backupdir      => '/tmp/backups',
#     backupcompress => true,
#   }
#
class mysql::backup (
  $backupuser,
  $backuppassword,
  $backupdir,
  $backupcompress = true,
  $backuprotate = 30,
  $ensure = 'present'
) {

  database_user { "${backupuser}@localhost":
    ensure        => $ensure,
    password_hash => mysql_password($backuppassword),
    provider      => 'mysql',
    require       => Class['mysql::config'],
  }

  database_grant { "${backupuser}@localhost":
    privileges => [ 'Select_priv' , 'Insert_priv' , 'Update_priv' , 'Delete_priv' , 'Create_priv' , 'Drop_priv' , 'Reload_priv' , 'Shutdown_priv' , 'Process_priv' , 'File_priv' , 'Grant_priv' , 'References_priv' , 'Index_priv' , 'Alter_priv' , 'Show_db_priv' , 'Super_priv' , 'Create_tmp_table_priv' , 'Lock_tables_priv' , 'Execute_priv' , 'Repl_slave_priv' , 'Repl_client_priv' , 'Create_view_priv' , 'Show_view_priv' , 'Create_routine_priv' , 'Alter_routine_priv' , 'Create_user_priv' , 'Event_priv' , 'Trigger_priv' , 'Create_tablespace_priv' ],
    require    => Database_user["${backupuser}@localhost"],
  }

  cron { 'mysql-backup':
    ensure  => $ensure,
    command => '/usr/local/sbin/mysqlbackup.sh',
    user    => 'root',
    hour    => 23,
    minute  => 5,
    require => File['mysqlbackup.sh'],
  }

  file { 'mysqlbackup.sh':
    ensure  => $ensure,
    path    => '/usr/local/sbin/mysqlbackup.sh',
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    content => template('mysql/mysqlbackup.sh.erb'),
  }

  file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
  }
}
