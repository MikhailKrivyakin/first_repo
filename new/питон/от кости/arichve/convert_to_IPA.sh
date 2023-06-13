#!/bin/sh
#
SourceData='cmudict-ru.txt'

cat ${SourceData} | \
while read RusWord PhoneticPart; do
#  echo "\"${RusWord}\"	${PhoneticPart}"
  echo -n "\"${RusWord}\"	"

  echo ${PhoneticPart} | tr ' ' "\n" | \
  while read Symbol; do
    case ${Symbol} in
    a0)  echo -n "ɐ " ;;
    a1)  echo -n "a " ;;
    b)   echo -n "b " ;;
    bj)  echo -n "bʲ " ;;
    c)   echo -n "t͡s " ;;
    ch)  echo -n "t͡ɕ " ;;
    d)   echo -n "d " ;;
    dj)  echo -n "dʲ " ;;
    e0)  echo -n "ɛ " ;;
    e1)  echo -n "e " ;;
    f)   echo -n "f " ;;
    fj)  echo -n "fʲ " ;;
    g)   echo -n "g " ;;
    gj)  echo -n "gʲ " ;;
    h)   echo -n "h " ;;
    hj)  echo -n "hʲ " ;;
    i0)  echo -n "ɪ " ;;
    i1)  echo -n "i " ;;
    j)   echo -n "j " ;;
    k)   echo -n "k " ;;
    kj)  echo -n "kʲ " ;;
    l)   echo -n "l " ;;
    lj)  echo -n "lʲ " ;;
    m)   echo -n "m " ;;
    mj)  echo -n "mʲ " ;;
    n)   echo -n "n " ;;
    nj)  echo -n "nʲ " ;;
    o0)  echo -n "ɵ " ;;
    o1)  echo -n "o " ;;
    p)   echo -n "p " ;;
    pj)  echo -n "pʲ " ;;
    r)   echo -n "r " ;;
    rj)  echo -n "rʲ " ;;
    s)   echo -n "s " ;;
    sch) echo -n "ɕː " ;;
    sh)  echo -n "ʂ " ;;
    sj)  echo -n "sʲ " ;;
    t)   echo -n "t " ;;
    tj)  echo -n "tʲ " ;;
    u0)  echo -n "ʊ " ;;
    u1)  echo -n "u " ;;
    v)   echo -n "v " ;;
    vj)  echo -n "vʲ " ;;
    y0)  echo -n "ɨ " ;;
    y1)  echo -n "ɨ " ;;
    z)   echo -n "z " ;;
    zh)  echo -n "ʐ " ;;
    zj)  echo -n "zʲ " ;;
    *)   echo -n "_${Symbol}_" ;;
    esac
  done
  echo
#  sleep 1
done

exit
