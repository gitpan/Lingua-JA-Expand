package Lingua::JA::Expand::Tokenizer::MeCab;

use strict;
use warnings;
use base qw(Lingua::JA::Expand::Tokenizer);
use List::MoreUtils qw(any);

sub tokenize {
    my $self      = shift;
    my $text_ref  = shift;
    my $threshold = shift;
    my $config    = $self->config->{tokenizer_config};
    $threshold ||= $config->{threshold};
    $threshold ||= 100;

    my %hash;

    if ($$text_ref) {

        $$text_ref =~ s/\r\n//g;
        $$text_ref =~ s/\n//g;
        $$text_ref =~ s/'//g;
        $$text_ref =~ s/"//g;
        $$text_ref =~ s/|//g;

        my $cmd =
            'echo \''
          . $$text_ref
          . '\' | mecab -b 100000 --node-format="%m\t%pw\t%H\n" --unk-format="%m\t%pw\t%H\tUNK\n"';
        my @ret = `$cmd`;

        my @NG_word = _NG();

        my %tf;
        my %info;
        my %cost;
        for (@ret) {
            chomp $_;
            my ( $word, $cost, $info, $unkown ) = split( /\t/, $_, 4 );
            next if !$info;
            if ( $info =~ /名詞/ ) {
                next if $info =~ /数|非自立|語幹|代名詞|接尾/;
                next if any { $word eq $_ } @NG_word;
                $tf{$word}++;
                $info{$word} = $info;
                $cost{$word} = $cost;
            }
        }

        my @sorted = sort { $tf{$b} <=> $tf{$a} or $cost{$b} <=> $cost{$a}; }
          keys %tf;

        my $i;
        for (@sorted) {
            $i++;
            last if ( $i > $threshold );
            $hash{$_} += $tf{$_};
        }

    }
    return \%hash;
}

sub _NG {
    return (
        '(', ')', '#', ',', '"', '\'', '`',
        qw(! $ % & * + - . / : ; < = > ? @ [ \ ] ^ _ { | } ~),
        qw(人 秒 分 時 日 月 年 円 ドル),
        qw(一 二 三 四 五 六 七 八 九 十 百 千 万 億 兆),
        qw(↑ ↓ ← → ⇒ ⇔ ＼ ＾ ｀ ヽ),
        qw(a any the who he she i to and in you is you str this ago about and new as of for if or it have by into at on an are were was be my am your we them there their from all its),
        qw(検索 サイト ホームページ 情報 関連 一覧 運営 お ご ... gt amp lt ー ¥ !! jp com :// htm html),
        qw(a b c d e f g h i j k l m n o p q r s t u v w x y z),
        qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z),
    );
}

1;

__END__

=head1 NAME

Lingua::JA::Expand::Tokenizer::MeCab - Tokenizer based on MeCab 

=head1 SYNOPSIS

  use Lingua::JA::Expand::Tokenizer::MeCab;
  use Data::Dumper;

  my $tokenizer = Lingua::JA::Expand::Tokenizer::MeCab->new(\%conf);
  my $word_set  = $tokenizer->tokenize(\$text);

  print Dumper $word_set;

=head1 DESCRIPTION

Lingua::JA::Expand::Tokenizer::MeCab is Tokenizer based on MeCab 

=head1 METHODS

=head2 tokenize()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

