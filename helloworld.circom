pragma circom 2.1.0;



template HelloWorld() {
    signal input in;
    signal output out;
    out <== in * in;
}

component main = HelloWorld();