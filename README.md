# Co-SNARK tutorial
## Trusted setup:
- Create original power of $\tau$:
```
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
```
- Create power of $\tau$ with a randomtext:
```
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="FirstTutorial" -v
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v
```
## Create all you need to apply ZKP by using circom:
- Create your circom file and compile it to r1cs:
```
circom helloworld.circom --r1cs
```
- create proving key and certification key from your .r1cs file:
```
# With groth16
snarkjs groth16 setup helloworld.r1cs pot12_final.ptau circuit.zkey
```
- Contribute:
```
snarkjs zkey contribute circuit.zkey circuit_final.zkey --name="FirstTutorial" -v
```
- export verification key:
```
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json
```
- We will give ``verification_key.json`` and ``circuit_final.zkey`` to all parties in MPC.
## Co-SNARK by using Co-circom:
- Config for all parties to joining computation. This config will be settings in ``.toml`` file:
```
[network]
my_id = 0
bind_addr = "0.0.0.0:10000"
key_path = "./data/key0.der"
[[network.parties]]
id = 0
# normally we would use DNS name here such as localhost, but localhost under windows is resolved to ::1, which causes problems since we bind to ipv4 above
dns_name = "127.0.0.1:10000"
cert_path = "./data/cert0.der"
[[network.parties]]
id = 1
dns_name = "127.0.0.1:10001"
cert_path = "./data/cert1.der"
[[network.parties]]
id = 2
dns_name = "127.0.0.1:10002"
cert_path = "./data/cert2.der"
```
_Note: You can get TLS certificate from [this](https://github.com/TaceoLabs/co-snarks/tree/main/co-circom/co-circom/examples/data)_
- split input by secret sharing protocol to all parties:
```
co-circom split-input --circuit helloworld.circom --input input.json --protocol REP3 --curve BN254 --out-dir out/ & 
co-circom split-input --circuit helloworld.circom --input input.json --protocol REP3 --curve BN254 --out-dir out/ & 
co-circom split-input --circuit helloworld.circom --input input.json --protocol REP3 --curve BN254 --out-dir out/
```
- After executing the above command, we provide each party with the secret sharing file corresponding to that party. For example, party 0 will receive ``input.json.0.shared``.
- Generate witness from secret sharing, We need all participating parties to do this at the same time.
```
co-circom generate-witness --input out/input.json.0.shared --circuit helloworld.circom --protocol REP3 --curve BN254 --config configs/party0.toml --out out/witness.wtns.0.shared &
co-circom generate-witness --input out/input.json.1.shared --circuit helloworld.circom --protocol REP3 --curve BN254 --config configs/party1.toml --out out/witness.wtns.1.shared &
co-circom generate-witness --input out/input.json.2.shared --circuit helloworld.circom --protocol REP3 --curve BN254 --config configs/party2.toml --out out/witness.wtns.2.shared
```
- Now each party has their own witness from secret shares.
- Generate proof, at this step, we still need all participating parties to do this at the same time.
```
co-circom generate-proof groth16 --witness out/witness.wtns.0.shared --zkey circuit_final.zkey --protocol REP3 --curve BN254 --config configs/party0.toml --out proof.0.json --public-input public_input.json &
co-circom generate-proof groth16 --witness out/witness.wtns.1.shared --zkey circuit_final.zkey --protocol REP3 --curve BN254 --config configs/party1.toml --out proof.1.json --public-input public_input.json &
co-circom generate-proof groth16 --witness out/witness.wtns.2.shared --zkey circuit_final.zkey --protocol REP3 --curve BN254 --config configs/party2.toml --out proof.2.json --public-input public_input.json
```
- Now, all parties have a same proof such that verifier just need to verify one proof, not all.
```
co-circom verify groth16 --proof proof.0.json --vk verification_key.json --public-input public_input.json --curve BN254
```
