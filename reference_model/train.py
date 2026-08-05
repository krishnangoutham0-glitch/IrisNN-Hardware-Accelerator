import torch
import torch.nn as nn
import torch.optim as optim

from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split

from model import IrisNN


# Load dataset
iris = load_iris()

X = iris.data
y = iris.target

# Split dataset
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# Convert to tensors
X_train = torch.tensor(X_train, dtype=torch.float32)
X_test = torch.tensor(X_test, dtype=torch.float32)

y_train = torch.tensor(y_train, dtype=torch.long)
y_test = torch.tensor(y_test, dtype=torch.long)


# Create model
model = IrisNN()

# Loss function
criterion = nn.CrossEntropyLoss()

# Optimizer
optimizer = optim.Adam(model.parameters(), lr=0.01)


epochs = 300

for epoch in range(epochs):

    optimizer.zero_grad()

    outputs = model(X_train)

    loss = criterion(outputs, y_train)

    loss.backward()

    optimizer.step()

    if (epoch + 1) % 10 == 0:
        print(f"Epoch {epoch+1:3d} | Loss = {loss.item():.4f}")


# Test accuracy
with torch.no_grad():

    outputs = model(X_test)

    prediction = torch.argmax(outputs, dim=1)

    accuracy = (prediction == y_test).float().mean()

print()
print(f"Test Accuracy = {accuracy.item()*100:.2f}%")
torch.save(model.state_dict(), "iris_model.pth")

print("\nModel saved as iris_model.pth")
# print("\n==============================")
# print("Layer 1 Weights (fc1.weight)")
# print("==============================")
# print(model.fc1.weight)

# print("\n==============================")
# print("Layer 1 Bias (fc1.bias)")
# print("==============================")
# print(model.fc1.bias)

# print("\n==============================")
# print("Layer 2 Weights (fc2.weight)")
# print("==============================")
# print(model.fc2.weight)

# print("\n==============================")
# print("Layer 2 Bias (fc2.bias)")
# print("==============================")
# print(model.fc2.bias)