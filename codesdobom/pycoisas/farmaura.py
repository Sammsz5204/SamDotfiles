num1 = float(input("Primeiro número: "))
operacao = input("Operação (+, -, *, /, %): ")
num2 = float(input("Segundo número: "))

if operacao == '+':
    resultado = num1 + num2
elif operacao == '-':
    resultado = num1 - num2
elif operacao == '*':
    resultado = num1 * num2
elif operacao == '/':
    if num2 != 0:
        resultado = num1 / num2
    else:
        resultado = "Erro: 'Imagine que você tem 0 biscoitos e os divide igualmente entre 0 amigos. Quantos biscoitos cada pessoa recebe? Veja, não faz sentido. E o Monstro das Bolachas está triste porque não há biscoitos. E você está triste porque não tem amigos.'"
elif operacao == '%':
    resultado = num1 % num2
else:
    resultado = "Erro: TALVEZ tenha algo errado no operador, jenio!"
print(resultado)