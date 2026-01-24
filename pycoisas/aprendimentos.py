num = input("escrevealgoaecacete:", )
operador = input("escreve o operador cacete:", )
num2 = input("escrevealgoaecacete:", )


if operador == "+":
    print (float(num) + float(num2))
elif operador == "-":
    print (float(num) - float(num2))
elif operador == "*":
    print (float(num) * float(num2))
elif operador == "/":
    print (float(num) / float(num2))
elif operador not in ["+", "-", "*", "/"]:
    print("operador invalido cacete")


