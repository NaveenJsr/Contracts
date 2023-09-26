// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FractionCalculator {
    struct Fraction {
        int256 num; // Numerator
        int256 den; // Denominator
    }

    function createFraction(int256 _num, int256 _den) internal pure returns (Fraction memory) {
        require(_den != 0, "Denominator cannot be zero");
        return Fraction(_num, _den);
    }

    function reduceFraction(Fraction memory f) internal pure returns (Fraction memory) {
        int256 gcdValue = gcd(f.num, f.den);
        f.num = f.num / gcdValue; // Cast to uint to maintain data type
        f.den = f.den / gcdValue; // Cast to uint to maintain data type
        return f;
    }

    function multiplyFractions(Fraction memory f1, Fraction memory f2) internal pure returns (Fraction memory) {
        int256 newNum = f1.num * f2.num;
        int256 newDen = f1.den * f2.den;
        Fraction memory result = createFraction(newNum, newDen);
        return reduceFraction(result);
    }

    function addFractions(Fraction memory f1, Fraction memory f2) internal pure returns (Fraction memory) {
        int256 newNum = f1.num * f2.den + f1.den * f2.num;
        int256 newDen = f1.den * f2.den;
        Fraction memory result = createFraction(newNum, newDen);
        return reduceFraction(result);
    }

    function gcd(int256 a, int256 b) internal pure returns (int256) {
        while (b != 0) {
            int256 temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }
}


contract ShamirSecretShare is FractionCalculator{

    struct Point{
        uint x;
        uint y;
    }

    Point[] points;
    uint[] x;
    uint[] y;

    mapping (uint => Point[]) SecretShares; 

    function addPoint(uint _x, uint _y) private  {
        Point memory newPoint = Point(_x, _y);
        points.push(newPoint);
        x.push(_x);
        y.push(_y);
        SecretShares[points.length - 1].push(newPoint);
        delete points;
    }

    function calculateY(uint _x, uint[] memory poly) private pure returns(uint){
        uint _y = 0;
        uint temp = 1;

        for(uint i = 0; i<poly.length; i++){
            _y = _y + (poly[i] * temp);
            temp = temp * _x;
        }

        return _y;
    }

    function generateRandomNumber() private view returns (uint256) {
        uint256 blockNumber = block.number;
        uint256 blockHash = uint256(blockhash(blockNumber - 1));
        uint256 randomNumber = blockHash % 100; // Adjust the range as needed
        return randomNumber;
    }

    function CreateShare(uint s, uint n, uint k) public {
        uint[] memory poly = new uint[](k); 

        poly[0] = s;

        for(uint j = 0; j < k; j++){
            uint p = 0;
            while (p == 0){
                uint random = generateRandomNumber();
                p = (random % 997);
            }
            poly[j] = p;
        }

        for(uint j = 1; j <= n; j++){
            uint _x = j;
            uint _y = calculateY(_x, poly);

            addPoint(_x, _y);
        }
    }

    function getAllShares(uint index) public view returns (int[] memory, int[] memory) {
        int[] memory resultx = new int[](SecretShares[index].length);
        int[] memory resulty = new int[](SecretShares[index].length);

        for (uint i = 0; i < SecretShares[index].length; i++) {
            resultx[i] = int(SecretShares[index][i].x);
            resulty[i] = int(SecretShares[index][i].y);
        }

        return (resultx, resulty);
    }

    function generateSecretOperation(int[] memory _x, int[] memory _y, uint m) private pure returns (int) {
        FractionCalculator.Fraction memory ans = FractionCalculator.Fraction(0, 1);

        for (uint i = 0; i < m; i++) {
            FractionCalculator.Fraction memory l = FractionCalculator.Fraction(_y[i], 1);
            for (uint j = 0; j < m; j++) {
                if (i != j) {
                    int256 tempNumerator = -int256(_x[i]);
                    int256 tempDenominator = int256(_x[i] - _x[j]);
                    FractionCalculator.Fraction memory temp = FractionCalculator.Fraction(tempNumerator, int256(tempDenominator));
                    l = FractionCalculator.multiplyFractions(l, temp);
                }
            }
            ans = FractionCalculator.addFractions(ans, l);
        }
        return ans.num;
    }

    function generateSecret(uint m, uint Shareindex) public view returns (uint) {
        int[] memory xShares;
        int[] memory yShares;
        (xShares, yShares) = getAllShares(Shareindex);
        int secret = generateSecretOperation(xShares, yShares, m);
        return uint(secret);
    }
}