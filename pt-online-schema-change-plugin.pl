use strict ;

package pt_online_schema_change_plugin ;

sub new {
   my ($class, %args) = @_;
   my $self = { %args };
   return bless $self, $class;
}

sub init {
    my ($self, %args) = @_;

    my $dbh = $self->{aux_cxn}->dbh;
    my @dbname = $dbh->selectrow_array("SELECT DATABASE()") ;
    my $hipchat_token = $ENV{'HIPCHAT_TOKEN'} ;
    my $alter_stmt = $self->{alter} ;

    if ( $self->{execute} ) {
        `curl -d "room_id=DB&from=pt-OSC-plugin&message=pt-online-schema-change+starting+alter+on+$dbh\n$alter_stmt&color=purple" https://api.hipchat.com/v1/rooms/message?auth_token=$hipchat_token&format=json`
        `curl -d "room_id=Announcements&from=pt-OSC-plugin&message=pt-online-schema-change+starting+alter+on+$dbh\n$alter_stmt&color=purple" https://api.hipchat.com/v1/rooms/message?auth_token=$hipchat_token&format=json`
    }
}

sub before_exit {
    my ($self, %args) = @_;

    my $dbh = $self->{aux_cxn}->dbh;
    my @dbname = $dbh->selectrow_array("SELECT DATABASE()") ;

    if ( $self->{execute} ) {
      `curl -d "room_id=DB&from=pt-OSC-plugin&message=pt-online-schema-change+finishing+alter+on+$dbh\n$alter_stmt&color=purple" https://api.hipchat.com/v1/rooms/message?auth_token=$hipchat_token&format=json`
      `curl -d "room_id=Announcements&from=pt-OSC-plugin&message=pt-online-schema-change+finishing+alter+on+$dbh\n$alter_stmt&color=purple" https://api.hipchat.com/v1/rooms/message?auth_token=$hipchat_token&format=json`
    }
}

sub before_create_new_table {
    my ($self, %args) = @_;

    # connect to the database, and verify that read_only==0
    my $dbh = $self->{aux_cxn}->dbh;

    my @is_read_only = $dbh->selectrow_array("SELECT \@\@read_only") ;

    if ( $is_read_only[0] != 0 ) {
        print "\nERROR: MySQL is running in read-only mode, bailing out!\n\n" ;
        exit 0 ;
    } else {
        return ;
    }
}

sub before_swap_tables {
    my ($self, %args) = @_;

    # connect to the database, collect, and print binay log stats
    my $dbh = $self->{aux_cxn}->dbh;

    my @master_status = $dbh->selectrow_array("SHOW MASTER STATUS") ;

    print "Captured binary log and position: @master_status\n" ;

    return ;
}
1 ;
