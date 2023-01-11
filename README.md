# Verifiable credentials (VCs)

__author__: Igor Podtsepko (i.podtsepko2002@gmail.com)

## Prerequirements

You will need to install dependencies before launching. To do this, use the following command:

```
$ npm install
```

## Running tests

To run the tests, use the command `npx hardhat test`. Example of test output:

```
  VerifiableDataRegistry
    ✔ Searches for a random address to be used as a verification object (93ms)
    ✔ The registry must be successfully deployed (123ms)
    ✔ A verifier for an untrusted address should not be found (43ms)
    ✔ The owner must be successfully registered as a verifier
    ✔ Cheks that the owner's address is now the address of the verifier
    ✔ Now there should be only one verifier
    ✔ Data about a verifier should be available
    ✔ Verifier data must be updated successfully (43ms)
    ✔ The verifier must be successfully removed
    ✔ The owner must successfully recreate himself as a verifier
    ✔  Based on the time stamp on the last block, the confirmation expiration time should be determined (4579ms)
    ✔ Should format a structured verification result
    ✔ The correct signature must be generated to verify the credentials
    ✔ The subject must not have a registered valid confirmation
    ✔ The subject must be successfully registered as verified (67ms)
    ✔ Information about the confirmation of the subject must be available.
    ✔ Information about all verifications for a subject address must be available
    ✔ Information about all verifications for a verifier address must be available
    ✔ Information about confirmation should be available by its UUID


  19 passing (5s)
```

## Running a demo

To demonstrate the capabilities of the implemented smart contract, a set of hardhat tasks and a script were also written for it demo.sh . Launch a local ethereum node (npx. hardhat node) and demo.sh it's like a regular bash script without arguments. As a result, the script will print the following scenario, and logs will be displayed in the terminal in which the node was started:

```
$ ./demo.sh 
# This is a script to demonstrate the capabilities of this DApp

REGISTRY="0x5FbDB2315678afecb367f032d93F642f64180aa3"

# 1) This command deploys the contract on the local network:
npx hardhat run scripts/deploy.js --network localhost
Deploying the contracts with the account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Account balance: 10000000000000000000000
Registry address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Added trusted verifier: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Added trusted verifier: 0x71CB05EE1b1F506fF321Da3dac38f25c0c9ce6E1
Registered Verification for address: 0x695f7BC02730E0702bf9c8C102C254F595B24161, by verifier: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Registered Verification for address: 0x71CB05EE1b1F506fF321Da3dac38f25c0c9ce6E1, by verifier: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Registered Verification for address: 0x70997970c51812dc3a010c7d01b50e0d17dc79c8, by verifier: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Registered Verification for address: 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc, by verifier: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Registered Verification for address: 0x90f79bf6eb2c4f870365e785982e1f101e93b906, by verifier: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# 2) This allows you to determine the number of verifiers:
npx hardhat getVerifierCount --registry $REGISTRY --network localhost
Number of verifiers: 2

# 3) This allows you to check whether the address is a trusted verifier
npx hardhat isVerifier --registry $REGISTRY --address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --network localhost
Is 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 a verifier? true

npx hardhat isVerifier --registry $REGISTRY --address 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc --network localhost
Is 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc a verifier? false

# 4) Similarly, you can work with verifiable credentials
npx hardhat getVerificationCount --registry $REGISTRY --network localhost
Verification Count: 5

npx hardhat isVerified --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost
Is 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 verified? false

npx hardhat isVerified --registry $REGISTRY --address 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc --network localhost
Is 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc verified? true

# 5) Other credentials can be verified:
npx hardhat registerVerification --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost
Registered Verification for address: 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199, by verifier 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

npx hardhat isVerified --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost
Is 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 verified? true

# 6) You can also get a list of all verified credentials at
# the verifier address using the following command:
npx hardhat getVerificationsForVerifier --registry $REGISTRY --verifier 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --network localhost
Verifications from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266:
0xa1c905be99522544e1f780e26f7576ee1dad0079b12690ca15d10df982ca9abd,0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0x695f7BC02730E0702bf9c8C102C254F595B24161,1674111598,1989471596,false
0x7fea861c8de960d7246326f28a5a42bb8aa364048693e78b417a6cbd14d37021,0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0x71CB05EE1b1F506fF321Da3dac38f25c0c9ce6E1,1674111599,1989471596,false
0xefa789ad82b97fe604b42fe77cbe766af3e3b31be570fff1fdb0500d4b99585a,0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0x70997970C51812dc3A010C7d01b50e0d17dc79C8,1674111600,1989471596,false
0xb3c2e040cf0223fd78e836670403a31fc5159a1ede79b01bfefe15e6f7fac0aa,0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,1674111601,1989471596,false
0x3f7f9a1a76409467105a003f5d00175793adfb2f9a5707b13532fcad47dad95a,0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0x90F79bf6EB2c4f870365E785982E1f101E93b906,1674111602,1989471596,false
0xd1b4210b7ec9af4063b72c2c829ec14b35ec3ef16e7ec5feafc1990944c85467,0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199,1674111609,1674111663,false

UUID=$(npx hardhat getVerificationsForVerifier --registry $REGISTRY --verifier 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --network localhost | grep 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 | awk -F ',' '{print $1}')
echo ${UUID} # Verifiable credentials has UUID (assined in smart-contract)
0xd1b4210b7ec9af4063b72c2c829ec14b35ec3ef16e7ec5feafc1990944c85467

# 7) If you have a UUID, you can cancel the confirmation:
npx hardhat revokeVerification --registry $REGISTRY --uuid ${UUID} --network localhost
Revoked verification with UUID: 0xd1b4210b7ec9af4063b72c2c829ec14b35ec3ef16e7ec5feafc1990944c85467

npx hardhat isVerified --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost
Is 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 verified? false
```
