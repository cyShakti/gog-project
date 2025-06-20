// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Credit Scoring
 * @dev A smart contract system for decentralized credit assessment
 * @author Decentralized Credit Scoring Team
 */
contract Project {
    // Struct to store user credit data
    struct CreditProfile {
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 defaultCount;
        uint256 onTimePayments;
        uint256 accountAge;
        uint256 lastUpdated;
        bool isActive;
        uint256 creditScore;
    }
    
    // Mapping to store credit profiles
    mapping(address => CreditProfile) public creditProfiles;
    
    // Mapping to track authorized lenders
    mapping(address => bool) public authorizedLenders;
    
    // Contract owner
    address public owner;
    
    // Events
    event CreditProfileCreated(address indexed user, uint256 timestamp);
    event CreditScoreUpdated(address indexed user, uint256 newScore, uint256 timestamp);
    event LenderAuthorized(address indexed lender, uint256 timestamp);
    event PaymentRecorded(address indexed user, uint256 amount, bool onTime, uint256 timestamp);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAuthorizedLender() {
        require(authorizedLenders[msg.sender], "Only authorized lenders can call this function");
        _;
    }
    
    modifier profileExists(address user) {
        require(creditProfiles[user].isActive, "Credit profile does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Create or update credit profile
     * @param user Address of the user
     * @param transactions Number of blockchain transactions
     * @param volume Total transaction volume in wei
     * @param accountAge Age of the account in days
     */
    function updateCreditProfile(
        address user,
        uint256 transactions,
        uint256 volume,
        uint256 accountAge
    ) external onlyAuthorizedLender {
        CreditProfile storage profile = creditProfiles[user];
        
        if (!profile.isActive) {
            // Create new profile
            profile.isActive = true;
            emit CreditProfileCreated(user, block.timestamp);
        }
        
        // Update profile data
        profile.totalTransactions = transactions;
        profile.totalVolume = volume;
        profile.accountAge = accountAge;
        profile.lastUpdated = block.timestamp;
        
        // Calculate and update credit score
        uint256 newScore = calculateCreditScore(user);
        profile.creditScore = newScore;
        
        emit CreditScoreUpdated(user, newScore, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Record payment history
     * @param user Address of the user
     * @param amount Payment amount
     * @param onTime Whether payment was made on time
     */
    function recordPayment(
        address user,
        uint256 amount,
        bool onTime
    ) external onlyAuthorizedLender profileExists(user) {
        CreditProfile storage profile = creditProfiles[user];
        
        if (onTime) {
            profile.onTimePayments++;
        } else {
            profile.defaultCount++;
        }
        
        profile.lastUpdated = block.timestamp;
        
        // Recalculate credit score
        uint256 newScore = calculateCreditScore(user);
        profile.creditScore = newScore;
        
        emit PaymentRecorded(user, amount, onTime, block.timestamp);
        emit CreditScoreUpdated(user, newScore, block.timestamp);
    }
    
    /**
     * @dev Core Function 3: Calculate credit score based on multiple factors
     * @param user Address of the user
     * @return creditScore Calculated credit score (0-850)
     */
    function calculateCreditScore(address user) public view profileExists(user) returns (uint256) {
        CreditProfile memory profile = creditProfiles[user];
        
        uint256 score = 300; // Base score
        
        // Transaction history factor (0-200 points)
        if (profile.totalTransactions > 0) {
            uint256 transactionScore = (profile.totalTransactions * 200) / 1000;
            if (transactionScore > 200) transactionScore = 200;
            score += transactionScore;
        }
        
        // Volume factor (0-150 points)
        uint256 volumeScore = (profile.totalVolume / 1 ether) * 10;
        if (volumeScore > 150) volumeScore = 150;
        score += volumeScore;
        
        // Payment history factor (0-200 points)
        uint256 totalPayments = profile.onTimePayments + profile.defaultCount;
        if (totalPayments > 0) {
            uint256 paymentRatio = (profile.onTimePayments * 100) / totalPayments;
            uint256 paymentScore = (paymentRatio * 200) / 100;
            score += paymentScore;
            
            // Penalty for defaults
            if (profile.defaultCount > 0) {
                uint256 penalty = profile.defaultCount * 50;
                if (penalty > score - 300) penalty = score - 300;
                score -= penalty;
            }
        }
        
        // Account age factor (0-100 points)
        uint256 ageScore = profile.accountAge / 10; // 1 point per 10 days
        if (ageScore > 100) ageScore = 100;
        score += ageScore;
        
        // Cap the score at 850
        if (score > 850) score = 850;
        
        return score;
    }
    
    /**
     * @dev Get credit profile information
     * @param user Address of the user
     * @return CreditProfile struct with all user data
     */
    function getCreditProfile(address user) external view profileExists(user) returns (CreditProfile memory) {
        return creditProfiles[user];
    }
    
    /**
     * @dev Get only the credit score for a user
     * @param user Address of the user
     * @return creditScore Current credit score
     */
    function getCreditScore(address user) external view profileExists(user) returns (uint256) {
        return creditProfiles[user].creditScore;
    }
    
    /**
     * @dev Authorize a lender to update credit profiles
     * @param lender Address of the lender to authorize
     */
    function authorizeLender(address lender) external onlyOwner {
        authorizedLenders[lender] = true;
        emit LenderAuthorized(lender, block.timestamp);
    }
    
    /**
     * @dev Revoke lender authorization
     * @param lender Address of the lender to revoke
     */
    function revokeLender(address lender) external onlyOwner {
        authorizedLenders[lender] = false;
    }
    
    /**
     * @dev Check if a user has an active credit profile
     * @param user Address to check
     * @return bool Whether user has active profile
     */
    function hasProfile(address user) external view returns (bool) {
        return creditProfiles[user].isActive;
    }
    
    /**
     * @dev Get credit rating category based on score
     * @param user Address of the user
     * @return string Credit rating (Excellent, Good, Fair, Poor)
     */
    function getCreditRating(address user) external view profileExists(user) returns (string memory) {
        uint256 score = creditProfiles[user].creditScore;
        
        if (score >= 750) return "Excellent";
        if (score >= 650) return "Good";
        if (score >= 550) return "Fair";
        return "Poor";
    }
}
