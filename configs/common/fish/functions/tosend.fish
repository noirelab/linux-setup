function tosend --description 'Envia arquivos direto pro tablet via KDE Connect'
    set -l dev 9aaf79f336fb475d815f814cc3e082dd

    if not kdeconnect-cli -a --id-only 2>/dev/null | grep -q $dev
        echo "tosend: tablet nao alcancavel. Abra o app KDE Connect nele."
        return 1
    end

    set -l files
    if test (count $argv) -gt 0
        set files $argv
    else
        for f in *
            set -a files $f
        end
    end

    if test (count $files) -eq 0
        echo "tosend: nenhum arquivo para enviar"
        return 1
    end

    for f in $files
        if test -d $f
            # KDE Connect nao envia diretorios; compacta antes
            set -l tgz /tmp/(basename $f).tgz
            tar czf $tgz -C (dirname $f) (basename $f); or return 1
            set f $tgz
        end
        kdeconnect-cli -d $dev --share (realpath $f); or return 1
        echo "  enviado: "(basename $f)
    end
end
