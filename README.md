# Decentralized Food Safety Inspection System

A comprehensive blockchain-based food safety inspection platform built on Stacks using Clarity smart contracts.

## Overview

This system provides a decentralized approach to food safety management, covering restaurant inspections, violation tracking, employee certifications, supply chain verification, and public reporting.

## Architecture

### Smart Contracts

1. **Restaurant Inspection Scheduling** (`restaurant-inspection.clar`)
    - Manages health department visit appointments
    - Schedules routine and complaint-based inspections
    - Tracks inspection status and results

2. **Violation Tracking** (`violation-tracking.clar`)
    - Records food safety infractions
    - Manages follow-up actions and remediation
    - Tracks violation severity and compliance

3. **Employee Certification** (`employee-certification.clar`)
    - Validates food handler training and licenses
    - Manages certification expiration and renewals
    - Links employees to restaurants

4. **Supply Chain Verification** (`supply-chain.clar`)
    - Tracks ingredient sourcing and quality standards
    - Manages supplier certifications
    - Records batch tracking and recalls

5. **Public Reporting** (`public-reporting.clar`)
    - Publishes inspection results for consumer transparency
    - Aggregates safety scores and ratings
    - Provides public access to safety data

## Features

- **Transparent Inspections**: All inspection data stored immutably on blockchain
- **Real-time Compliance**: Automated tracking of violations and remediation
- **Employee Management**: Comprehensive certification and training tracking
- **Supply Chain Integrity**: End-to-end ingredient and supplier verification
- **Public Access**: Consumer-facing safety information and ratings

## Data Types

### Restaurant
- ID, name, address, license number
- Owner information and contact details
- Operating status and inspection history

### Inspection
- Scheduled date/time and inspector assignment
- Inspection type (routine, complaint, follow-up)
- Results, score, and violation details

### Violation
- Type, severity level, and description
- Remediation requirements and deadlines
- Follow-up inspection scheduling

### Employee Certification
- Employee ID and restaurant association
- Certification type, issue/expiry dates
- Training completion status

### Supply Chain Record
- Supplier information and certifications
- Ingredient batch tracking
- Quality standards compliance

## Getting Started

### Prerequisites
- Clarinet CLI
- Node.js and npm
- Stacks wallet for testing

### Installation

\`\`\`bash
git clone <repository-url>
cd food-safety-inspection
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Schedule an Inspection
\`\`\`clarity
(contract-call? .restaurant-inspection schedule-inspection
u1 ;; restaurant-id
u1640995200 ;; scheduled-time
"routine" ;; inspection-type
)
\`\`\`

### Record a Violation
\`\`\`clarity
(contract-call? .violation-tracking record-violation
u1 ;; restaurant-id
"temperature-control" ;; violation-type
u3 ;; severity (1-5)
"Refrigeration unit temperature above safe limits"
)
\`\`\`

### Verify Employee Certification
\`\`\`clarity
(contract-call? .employee-certification verify-certification
u1 ;; employee-id
u1 ;; restaurant-id
)
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Inspector and health department roles are managed
- Data integrity maintained through blockchain immutability
- Public data carefully filtered to protect sensitive information

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

MIT License - see LICENSE file for details.
