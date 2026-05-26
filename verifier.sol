pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            switch success case 0 { invalid() }
        }
        require(success);
    }
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            switch success case 0 { invalid() }
        }
        require (success);
    }
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x226496a941f355da9ec3a648df81ee25ac174a6846989d0743f243c3ed0053d7), uint256(0x1b077e561b63b0c90185bc5a2bae5c4cc6edfc55edd3bdab198cda2e4d2cef9a));
        vk.beta = Pairing.G2Point([uint256(0x1343f0614a6d2ec0997834d07bc7edc0f44d1d3385179f065dc3aad065054802), uint256(0x20b08fe3d71862c6c7e0ef0cb6f97161f486fc2d7a89fae7e66f3764aca91c39)], [uint256(0x0051f8f48aa045ba92f04741539775526ea2e6bf18fc8dff94afe46ad72b1ab0), uint256(0x2decc276368002a341fc42c6a6613ba682541faa8dcbf1c08e0758ed1ba89176)]);
        vk.gamma = Pairing.G2Point([uint256(0x14b2469ff0c3495beaaf5f8f7f8f6295a73d0feb587bff9189c1790ff8207da4), uint256(0x2de6236a958b8d503519b05869bf1757b2927e9e1abbee78bfd09f868faae43a)], [uint256(0x00945c01925eadc06264aa0ac323796826b54cbcef525cefc03abd96eb087f7c), uint256(0x185bb9ec6c3f056f482a7b0f130726ac5e81169dc118f784fcc92ebf111911d1)]);
        vk.delta = Pairing.G2Point([uint256(0x042c3a0cac031c221ddbffc8752e424830abc0263ed656706ac3bca704b0cb7b), uint256(0x0abe4277ecaed02fb93a805c07dabb2ee25021b439000c4064d6753424609b9a)], [uint256(0x09e586781cf834d4da8dc3e9ca7c7ae0ca5c7bbd2686f2cdfca12eaf8e7d6a91), uint256(0x2c43982282ab3576f3bffcdeb8579074f56aa7e7e7b6151f44ca4841d8eb08fd)]);
        vk.gamma_abc = new Pairing.G1Point[](9);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1cffacd2a241407ad05dceca98aea87bc64e9a59a90defba93832f27f25260b1), uint256(0x128e199e3cfc7985fb1b765f0303f0b1baa3bb43e16973936f0bd04171d1f665));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x158872cda02f4d4cde5ab2e4483aa07c4f92bb8d58e09e79e3c0c6348e8fbea0), uint256(0x27f9d8cc39d41b60851232855a853935e16236d03cbdd704e684551742e187b0));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x26cd96ce8fa3aed3382daa9f94a2ea8feaa6dee2369656756e1f4f83d779ffe4), uint256(0x072c383ea7cd56bb9067c81d15726fb31a467c609c73b6fb5e026ed340c742b3));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x21dc578c2a53d5c50eb544777c47f7f817b2f3f69638bae1432e4e824b8355b2), uint256(0x2bb58483730c683fa377d40d08816ce5f583cb8c56aa9f2c68314aa7af48baa9));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0190dc0b6bbafea5f688be8d14bf0f24ded31cafd23e3315a44b1b787442023f), uint256(0x037f436e455d1fdb51d48334fb403aab512e1928a9ba40fcb998b2a279d17545));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x02df53a8998c531089e32c512e01010e472f481a08164c8f1af0a4789da08f8d), uint256(0x0dd8b44dabf7f8a6dfe29ec13936b917ce3e3039540e8f5c55ce7642e04db51b));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x16ae2a6cb38ac69170a000b4810665e7766b2488096654ffd20eae529e1acda2), uint256(0x2d0fa5a7719bc460126cc8cb35ef5c81a273da5741573690cdea8ded975cf679));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x16036c4e5c5ee21048a6d3aa374bb41863b1f3cf7f6e6400beb9bbf2f6691fbf), uint256(0x190609ab2b5122cf150dd034161c738c47109e779a58b322f0d87b714b6df7b2));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1b5c2f11dc3d3a32806bd4ceda7731f2de7148df350146aa822c31667353a125), uint256(0x1488d1bf6ca740b31adb653789fbd2508726765660a4163f07d1f727d3bb0425));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[8] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](8);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
