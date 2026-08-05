import torch
from sklearn.datasets import load_iris
from model import IrisNN

# -----------------------------
# Load trained model
# -----------------------------
model = IrisNN()
model.load_state_dict(torch.load("iris_model.pth"))
model.eval()

# -----------------------------
# Load first flower
# -----------------------------
iris = load_iris()

x = torch.tensor(iris.data[0], dtype=torch.float32)

weights = model.fc1.weight[0]
bias = model.fc1.bias[0]

# -----------------------------
# MAC Simulation
# -----------------------------
acc = 0.0

print("=" * 50)
print("MAC SIMULATION")
print("=" * 50)

for cycle in range(4):

    product = x[cycle] * weights[cycle]

    print(f"\nClock Cycle {cycle+1}")
    print("---------------------")
    print(f"Input      : {x[cycle]:8.4f}")
    print(f"Weight     : {weights[cycle]:8.4f}")
    print(f"Product    : {product:8.4f}")

    acc += product.item()

    print(f"Accumulator: {acc:8.4f}")

print("\nClock Cycle 5")
print("---------------------")
print(f"Bias        : {bias:8.4f}")

acc += bias.item()

print(f"Accumulator : {acc:8.4f}")

print("\nClock Cycle 6")
print("---------------------")

relu = max(0.0, acc)

print(f"ReLU Output : {relu:8.4f}")

# -----------------------------
# Verification
# -----------------------------
with torch.no_grad():

    pytorch = model.fc1(x)[0].item()

print("\n" + "=" * 50)
print(f"PyTorch Output : {pytorch:.4f}")
print(f"Simulator      : {relu:.4f}")
print(f"Difference     : {abs(pytorch-relu):.8f}")
print("=" * 50)