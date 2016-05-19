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

    if ( $self->{execute} ) {
        `nodebot dba "pt-online-schema-change starting alter in $dbname[0]: $self->{alter}"` ;
    }
}

sub before_exit {
    my ($self, %args) = @_;

    my $dbh = $self->{aux_cxn}->dbh;
    my @dbname = $dbh->selectrow_array("SELECT DATABASE()") ;

    if ( $self->{execute} ) {
        `nodebot dba "pt-online-schema-change finishing alter in $dbname[0]: $self->{alter}"` ;
    }
}

sub get_slave_lag {
    my ($self, %args) = @_;

    # oktorun is a reference, also update it using $$oktorun=0;
    my $oktorun=$args{oktorun};

    # This is a good place to check that you have everything you need
    # to verify replication across all calls to get_slave_lag. 

    my $lag = sub {

        # this subroutine will be called every time pt-online-schema-change
        # calls get_slave_lag (which is done by default for each replica 
        # detected). In our case, we set recurse=0 and get_slave_lag calls a 
        # central service that gives us the lag amount across the entire 
        # replication hierarchy. 
        #
        # You can do anything you want! For testing purposes here, we'll
        # just set it to 3.
        my $current_lag = 3 ; 

        if ($current_lag =~ /^\d+$/) {
            $$oktorun = 1 ;
            return $current_lag ;
        } else {
            print STDERR "ERROR: Bailling out, failed to get slave lag!\n" ;
           $$oktorun = 0 ;
           exit ;
        }

    } ;
    return $lag ;
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
