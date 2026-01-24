import pygame
import math

# Inicialização
pygame.init()
LARGURA, ALTURA = 800, 600
tela = pygame.display.set_mode((LARGURA, ALTURA))
pygame.display.set_caption("FPS simples em Python")

clock = pygame.time.Clock()

# Mapa (1 = parede, 0 = vazio)
MAPA = [
    "1111111111",
    "1000000001",
    "1000110001",
    "1000000001",
    "1011000001",
    "1000000001",
    "1000000001",
    "1111111111"
]

TAM_BLOCO = 64
FOV = math.pi / 3
MEIO_FOV = FOV / 2
NUM_RAIOS = 120
DIST_PROJ = (LARGURA / 2) / math.tan(MEIO_FOV)

# Jogador
px, py = 160, 160
angulo = 0
vel = 3

def desenhar_mapa():
    for y, linha in enumerate(MAPA):
        for x, bloco in enumerate(linha):
            if bloco == "1":
                pygame.draw.rect(
                    tela,
                    (100, 100, 100),
                    (x * TAM_BLOCO // 4, y * TAM_BLOCO // 4, 16, 16)
                )

def raycasting():
    for raio in range(NUM_RAIOS):
        angulo_raio = angulo - MEIO_FOV + (raio / NUM_RAIOS) * FOV
        for profundidade in range(1, 800):
            alvo_x = px + math.cos(angulo_raio) * profundidade
            alvo_y = py + math.sin(angulo_raio) * profundidade

            mapa_x = int(alvo_x // TAM_BLOCO)
            mapa_y = int(alvo_y // TAM_BLOCO)

            if MAPA[mapa_y][mapa_x] == "1":
                dist = profundidade * math.cos(angulo_raio - angulo)
                altura = min(50000 / (dist + 0.1), ALTURA)

                cor = 255 / (1 + dist * dist * 0.0001)
                pygame.draw.rect(
                    tela,
                    (cor, cor, cor),
                    (
                        raio * (LARGURA // NUM_RAIOS),
                        (ALTURA // 2) - altura // 2,
                        (LARGURA // NUM_RAIOS),
                        altura
                    )
                )
                break

# Loop principal
rodando = True
while rodando:
    tela.fill((30, 30, 30))

    for evento in pygame.event.get():
        if evento.type == pygame.QUIT:
            rodando = False

    teclas = pygame.key.get_pressed()

    if teclas[pygame.K_w]:
        px += math.cos(angulo) * vel
        py += math.sin(angulo) * vel
    if teclas[pygame.K_s]:
        px -= math.cos(angulo) * vel
        py -= math.sin(angulo) * vel
    if teclas[pygame.K_a]:
        angulo -= 0.05
    if teclas[pygame.K_d]:
        angulo += 0.05

    raycasting()
    desenhar_mapa()

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
