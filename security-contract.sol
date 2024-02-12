pragma solidity ^0.8.17;
contract DonationsContract  {
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    // Function to manually send Ether to the contract
    function sendEth() external payable {
        // The value sent with the transaction is automatically added to the contract's balance
    }
    // Optional: Function to check the balance of the contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
}
