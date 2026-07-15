# Zog (Breakout em Zig)

Este repositório é um **port em Zig** do tutorial de jogo **Breakout** feito originalmente em **Odin**, usando a biblioteca **raylib-zig**.

A implementação segue a ideia apresentada no vídeo abaixo, adaptando estrutura, sintaxe e fluxo para Zig.

## Referência

Tutorial no YouTube (Breakout em Odin):
https://youtu.be/vfgZOEvO0kM?si=xgCC8wHiSuMrjii7

## Tecnologias

- [Zig](https://ziglang.org/)
- [raylib-zig](https://github.com/Not-Nik/raylib-zig)
- [raylib](https://www.raylib.com/)

## Sobre o projeto

O jogo implementa uma versão clássica de Breakout com:

- Controle de paddle
- Bola com colisão em paredes, paddle e blocos
- Pontuação por bloco destruído
- Estado de início, jogo em andamento e game over
- Efeitos sonoros para colisões e fim de jogo

## Como executar

Com Zig instalado, rode:

```bash
zig build run
```

## Créditos

- Tutorial original em Odin: vídeo de referência acima
- Port para Zig deste repositório usando raylib-zig
