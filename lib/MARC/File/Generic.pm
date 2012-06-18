package MARC::File::Generic;

use strict;
use warnings;
use MARC::Record;

# MARC::Record -> generic hash
sub encode {
    my $record = shift;

    return {
        leader => $record->leader,
        fields => [ map {
            $_->tag,
            ( $_->is_control_field
              ? $_->data
              : {
                  ind1 => $_->indicator(1),
                  ind2 => $_->indicator(2),
                  subfields => [ map { ($_->[0], $_->[1]) } $_->subfields ],
                }
            )
        } $record->fields ],
    };
}

# generic hash -> MARC::Record
sub decode {
    my $data = shift;
    my $record = MARC::Record->new();
    $record->leader( $data->{leader} );

    my @fields;
    @_ = @{$data->{fields}};
    while ( @_ ) {
        my ($tag, $val) = (shift, shift);
        my @attrs
            = ref($val) eq 'HASH'
                ? ( $val->{ind1}, $val->{ind2}, @{$val->{subfields}} )
                : ( $val );
        push @fields, MARC::Field->new( $tag, @attrs );
    }

    $record->insert_fields_ordered( @fields );
    return $record;
}

### Methods injected into MARC::Record

sub MARC::Record::new_from_generic {
    my ($class, $data) = @_;
    return decode( $data );
}

sub MARC::Record::as_generic {
    my $self = shift;
    return encode( $self );
}

1;
