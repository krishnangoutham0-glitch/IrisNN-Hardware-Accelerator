import torch
import struct

# ------------------------------------------------------------
# Load your trained model
# ------------------------------------------------------------

# CHANGE THIS to however your model is currently loaded.
#
# Example:
# model = IrisNN()
# model.load_state_dict(torch.load("model.pth"))

from model import IrisNN

model = IrisNN()

model.load_state_dict(
    torch.load("reference_model/iris_model.pth", map_location="cpu")
)

model.eval()


# ------------------------------------------------------------
# Convert Python float -> IEEE-754 FP32 hex
# ------------------------------------------------------------

def float_to_hex(value):
    return f"{struct.unpack('<I', struct.pack('<f', float(value)))[0]:08X}"


# ------------------------------------------------------------
# Find the two Linear layers
# ------------------------------------------------------------

linear_layers = [
    module for module in model.modules()
    if isinstance(module, torch.nn.Linear)
]

if len(linear_layers) != 2:
    raise RuntimeError(
        f"Expected 2 Linear layers, found {len(linear_layers)}"
    )

hidden = linear_layers[0]
output = linear_layers[1]


# ------------------------------------------------------------
# Print hidden layer
# ------------------------------------------------------------

print()
print("=" * 60)
print("HIDDEN LAYER")
print("=" * 60)

print("\nWeights:")

for i in range(4):

    values = []

    for j in range(4):

        value = hidden.weight[i][j].item()

        values.append(float_to_hex(value))

    print(
        f"Neuron {i}: " +
        " ".join(values)
    )


print("\nBias:")

for i in range(4):

    value = hidden.bias[i].item()

    print(
        f"bias{i} = {float_to_hex(value)}"
    )


# ------------------------------------------------------------
# Print output layer
# ------------------------------------------------------------

print()
print("=" * 60)
print("OUTPUT LAYER")
print("=" * 60)

print("\nWeights:")

for i in range(3):

    values = []

    for j in range(4):

        value = output.weight[i][j].item()

        values.append(float_to_hex(value))

    print(
        f"Neuron {i}: " +
        " ".join(values)
    )


print("\nBias:")

for i in range(3):

    value = output.bias[i].item()

    print(
        f"bias{i} = {float_to_hex(value)}"
    )


# ------------------------------------------------------------
# Generate Verilog assignments
# ------------------------------------------------------------

print()
print("=" * 60)
print("VERILOG ASSIGNMENTS")
print("=" * 60)


print("\n// Hidden layer")

for i in range(4):

    for j in range(4):

        value = hidden.weight[i][j].item()

        print(
            f"hw{i}{j} = 32'h{float_to_hex(value)};"
        )

    value = hidden.bias[i].item()

    print(
        f"hb{i} = 32'h{float_to_hex(value)};"
    )


print("\n// Output layer")

for i in range(3):

    for j in range(4):

        value = output.weight[i][j].item()

        print(
            f"ow{i}{j} = 32'h{float_to_hex(value)};"
        )

    value = output.bias[i].item()

    print(
        f"ob{i} = 32'h{float_to_hex(value)};"
    )


print()
print("=" * 60)
print("DONE")
print("=" * 60)