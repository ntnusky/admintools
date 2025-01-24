import sys

# For each line of the input file, encode it with IDNA (punycode) and write it to the output file

if len(sys.argv) != 3:
    raise ValueError("Usage: python idna-encode-file.py <input_file> <output_file>")

filename_in = sys.argv[1]
filename_out = sys.argv[2]
with open(filename_out, "w") as f_out:
    with open(filename_in, "r", encoding="utf-8", errors="strict") as f_in:
        for line in f_in:
            f_out.write(line.strip().encode("idna").decode() + "\n")
