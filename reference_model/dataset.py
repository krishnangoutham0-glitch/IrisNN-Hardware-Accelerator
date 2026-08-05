from sklearn.datasets import load_iris

iris = load_iris()

print("First Flower")
print(iris.data[0])

print()

print("Target")
print(iris.target[0])

print()

print("Flower Name")
print(iris.target_names[iris.target[0]])