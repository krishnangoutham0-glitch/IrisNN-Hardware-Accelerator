import struct
from sklearn.datasets import load_iris


def float_to_hex(value):
    bits = struct.unpack(
        ">I",
        struct.pack(">f", float(value))
    )[0]

    return f"32'h{bits:08X}"


iris = load_iris()

X = iris.data
Y = iris.target

NUM_SAMPLES = 10

output_file = "tb/iris_test_vectors.vh"


with open(output_file, "w") as f:

    f.write("//============================================================\n")
    f.write("// AUTO-GENERATED IRIS TEST VECTORS\n")
    f.write("//============================================================\n\n")

    f.write(f"localparam integer NUM_IRIS_SAMPLES = {NUM_SAMPLES};\n\n")

    f.write(
        "reg [31:0] iris_x0 [0:NUM_IRIS_SAMPLES-1];\n"
    )
    f.write(
        "reg [31:0] iris_x1 [0:NUM_IRIS_SAMPLES-1];\n"
    )
    f.write(
        "reg [31:0] iris_x2 [0:NUM_IRIS_SAMPLES-1];\n"
    )
    f.write(
        "reg [31:0] iris_x3 [0:NUM_IRIS_SAMPLES-1];\n"
    )
    f.write(
        "reg [1:0] iris_class [0:NUM_IRIS_SAMPLES-1];\n\n"
    )

    for i in range(NUM_SAMPLES):

        f.write(
            f"assign iris_x0[{i}] = "
            f"{float_to_hex(X[i][0])}; "
            f"// {X[i][0]}\n"
        )

        f.write(
            f"assign iris_x1[{i}] = "
            f"{float_to_hex(X[i][1])}; "
            f"// {X[i][1]}\n"
        )

        f.write(
            f"assign iris_x2[{i}] = "
            f"{float_to_hex(X[i][2])}; "
            f"// {X[i][2]}\n"
        )

        f.write(
            f"assign iris_x3[{i}] = "
            f"{float_to_hex(X[i][3])}; "
            f"// {X[i][3]}\n"
        )

        f.write(
            f"assign iris_class[{i}] = "
            f"2'd{Y[i]}; "
            f"// {iris.target_names[Y[i]]}\n"
        )

        f.write("\n")


print("==============================================")
print("IRIS VERILOG TEST VECTOR GENERATOR")
print("==============================================")

print(f"Generated {NUM_SAMPLES} samples")
print(f"Output: {output_file}")

for i in range(NUM_SAMPLES):

    print(
        f"Sample {i}: "
        f"[{X[i][0]}, {X[i][1]}, "
        f"{X[i][2]}, {X[i][3]}] "
        f"-> class {Y[i]}"
    )

print("==============================================")