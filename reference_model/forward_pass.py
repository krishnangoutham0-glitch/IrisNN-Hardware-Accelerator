import torch
from sklearn.datasets import load_iris

from model import IrisNN

# ----------------------------
# Load trained model
# ----------------------------

model = IrisNN()

model.load_state_dict(torch.load("iris_model.pth"))

model.eval()

# ----------------------------
# Load dataset
# ----------------------------

iris = load_iris()

# First flower
x = torch.tensor(iris.data[0], dtype=torch.float32)

print("\nFlower Features")
print(x)

print("\nExpected Flower")
print(iris.target_names[iris.target[0]])

# ----------------------------
# Extract first neuron
# ----------------------------

weights = model.fc1.weight[0]
bias = model.fc1.bias[0]

print("\nFirst Hidden Neuron")

print("Weights :", weights)
print("Bias    :", bias)

print("\n----------------------------")

# ----------------------------
# Manual Calculation
# ----------------------------

products = x * weights

for i in range(4):
    print(f"x{i+1} = {x[i]:8.4f}")
    print(f"w{i+1} = {weights[i]:8.4f}")
    print(f"Product = {products[i]:8.4f}")
    print()

sum_value = torch.sum(products)

print("----------------------------")
print(f"Sum of Products = {sum_value:.4f}")

biased_output = sum_value + bias

print(f"After Bias      = {biased_output:.4f}")

relu_output = torch.relu(biased_output)

print(f"After ReLU      = {relu_output:.4f}")

print("----------------------------")

# ----------------------------
# Verify with PyTorch
# ----------------------------

with torch.no_grad():

    fc1_output = model.fc1(x)

print("\nPyTorch Hidden Neuron Output")

print(fc1_output[0])

print("\nDifference")

print(fc1_output[0] - biased_output)