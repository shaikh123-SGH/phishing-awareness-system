-- ============================================================================
--  Phishing Scam & Fraud Detection Awareness Program
--  MySQL schema + realistic sample data
--  Run with:  mysql -u root -p < database.sql
--  NOTE: every example below is FICTIONAL. No real credentials are stored.
-- ============================================================================

DROP DATABASE IF EXISTS phishing_awareness;
CREATE DATABASE phishing_awareness CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE phishing_awareness;

-- ---------------------------------------------------------------- users -----
CREATE TABLE users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    age_group     VARCHAR(20)  DEFAULT NULL,
    occupation    VARCHAR(60)  DEFAULT NULL,
    city          VARCHAR(60)  DEFAULT NULL,
    is_active     TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_users_email (email),
    INDEX idx_users_created (created_at)
) ENGINE=InnoDB;

-- --------------------------------------------------------------- admins -----
CREATE TABLE admins (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------ scam_categories -----
CREATE TABLE scam_categories (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    slug          VARCHAR(60)  NOT NULL UNIQUE,
    name          VARCHAR(80)  NOT NULL,
    icon          VARCHAR(40)  NOT NULL DEFAULT 'shield',
    summary       VARCHAR(255) NOT NULL,
    what_is_it    TEXT NOT NULL,
    how_it_works  TEXT NOT NULL,
    warning_signs TEXT NOT NULL,   -- one warning sign per line
    example_text  TEXT NOT NULL,
    stay_safe     TEXT NOT NULL,   -- one tip per line
    if_targeted   TEXT NOT NULL,   -- one step per line
    risk_level    ENUM('low','medium','high') NOT NULL DEFAULT 'high',
    display_order INT NOT NULL DEFAULT 0,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_cat_slug (slug)
) ENGINE=InnoDB;

-- -------------------------------------------------------- scam_examples -----
CREATE TABLE scam_examples (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    category_id   INT DEFAULT NULL,
    channel       ENUM('sms','email','whatsapp','call','webpage','payment') NOT NULL,
    sender        VARCHAR(120) NOT NULL,
    subject       VARCHAR(160) DEFAULT NULL,
    body          TEXT NOT NULL,
    is_scam       TINYINT(1) NOT NULL,
    explanation   TEXT NOT NULL,
    warning_signs TEXT NOT NULL,
    difficulty    ENUM('easy','medium','hard') NOT NULL DEFAULT 'easy',
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_example_category FOREIGN KEY (category_id)
        REFERENCES scam_categories(id) ON DELETE SET NULL,
    INDEX idx_example_channel (channel),
    INDEX idx_example_active (is_active)
) ENGINE=InnoDB;

-- -------------------------------------------------------- quiz_questions ----
CREATE TABLE quiz_questions (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    quiz_type     ENUM('pre','post','general') NOT NULL DEFAULT 'general',
    category_id   INT DEFAULT NULL,
    question      VARCHAR(400) NOT NULL,
    explanation   TEXT NOT NULL,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_question_category FOREIGN KEY (category_id)
        REFERENCES scam_categories(id) ON DELETE SET NULL,
    INDEX idx_question_type (quiz_type, is_active)
) ENGINE=InnoDB;

-- ---------------------------------------------------------- quiz_options ----
CREATE TABLE quiz_options (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    option_text VARCHAR(300) NOT NULL,
    is_correct  TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_option_question FOREIGN KEY (question_id)
        REFERENCES quiz_questions(id) ON DELETE CASCADE,
    INDEX idx_option_question (question_id)
) ENGINE=InnoDB;

-- --------------------------------------------------------- quiz_attempts ----
CREATE TABLE quiz_attempts (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    quiz_type     ENUM('pre','post','spot') NOT NULL,
    score         INT NOT NULL DEFAULT 0,
    total         INT NOT NULL DEFAULT 0,
    percentage    INT NOT NULL DEFAULT 0,
    awareness_level VARCHAR(30) NOT NULL DEFAULT 'Moderate',
    attempted_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_attempt_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_attempt_user_type (user_id, quiz_type),
    INDEX idx_attempt_date (attempted_at)
) ENGINE=InnoDB;

-- ---------------------------------------------------------- quiz_answers ----
CREATE TABLE quiz_answers (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    attempt_id   INT NOT NULL,
    question_id  INT DEFAULT NULL,
    example_id   INT DEFAULT NULL,
    given_answer VARCHAR(300) NOT NULL,
    is_correct   TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_answer_attempt FOREIGN KEY (attempt_id)
        REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    CONSTRAINT fk_answer_question FOREIGN KEY (question_id)
        REFERENCES quiz_questions(id) ON DELETE SET NULL,
    CONSTRAINT fk_answer_example FOREIGN KEY (example_id)
        REFERENCES scam_examples(id) ON DELETE SET NULL,
    INDEX idx_answer_attempt (attempt_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------- videos ----
CREATE TABLE videos (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    title         VARCHAR(150) NOT NULL,
    youtube_id    VARCHAR(20)  NOT NULL,
    video_url     VARCHAR(300) NOT NULL,
    description   TEXT,
    category_id   INT DEFAULT NULL,
    thumbnail_url VARCHAR(300) DEFAULT NULL,
    status        ENUM('draft','published') NOT NULL DEFAULT 'published',
    views         INT NOT NULL DEFAULT 0,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_video_category FOREIGN KEY (category_id)
        REFERENCES scam_categories(id) ON DELETE SET NULL,
    INDEX idx_video_status (status),
    INDEX idx_video_created (created_at)
) ENGINE=InnoDB;

-- ---------------------------------------------------- learning_resources ----
CREATE TABLE learning_resources (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    title         VARCHAR(160) NOT NULL,
    resource_type ENUM('article','checklist','infographic','poster','tip') NOT NULL,
    category_id   INT DEFAULT NULL,
    summary       VARCHAR(300) NOT NULL,
    content       LONGTEXT NOT NULL,
    file_path     VARCHAR(300) DEFAULT NULL,
    is_published  TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_resource_category FOREIGN KEY (category_id)
        REFERENCES scam_categories(id) ON DELETE SET NULL,
    INDEX idx_resource_type (resource_type, is_published)
) ENGINE=InnoDB;

-- --------------------------------------------------------- safety_topics ----
CREATE TABLE safety_topics (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    slug     VARCHAR(60) NOT NULL UNIQUE,
    title    VARCHAR(100) NOT NULL,
    icon     VARCHAR(40) NOT NULL DEFAULT 'lock',
    summary  VARCHAR(255) NOT NULL,
    tips     TEXT NOT NULL,           -- one tip per line
    display_order INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- -------------------------------------------------------------- feedback ----
CREATE TABLE feedback (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT DEFAULT NULL,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(120) DEFAULT NULL,
    rating      TINYINT NOT NULL,
    message     TEXT NOT NULL,
    suggestions TEXT,
    is_read     TINYINT(1) NOT NULL DEFAULT 0,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feedback_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_feedback_created (created_at)
) ENGINE=InnoDB;

-- --------------------------------------------------------- user_progress ----
CREATE TABLE user_progress (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    category_id  INT NOT NULL,
    completed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_progress_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_progress_category FOREIGN KEY (category_id)
        REFERENCES scam_categories(id) ON DELETE CASCADE,
    UNIQUE KEY uq_progress (user_id, category_id)
) ENGINE=InnoDB;

-- ===================== SAMPLE DATA (all examples fictional) =============

INSERT INTO admins (full_name, email, password_hash) VALUES
  ('Program Administrator', 'admin@awareness.local', 'pbkdf2:sha256:600000$7ec730497a8c6106$4e29f11f6dfb591dbbfd519c9077be7318071f305f135e6889f113af8af5c2b8');

INSERT INTO users (full_name, email, password_hash, age_group, occupation, city) VALUES
  ('Aarav Sharma', 'aarav@example.com', 'pbkdf2:sha256:600000$77f41c62dd6c2a17$ad16f8058d643e41baef322cc8112dd5a9133c34914b513594245a2146c54bca', '18-25', 'Student', 'Pune'),
  ('Meera Nair', 'meera@example.com', 'pbkdf2:sha256:600000$efa261af4fec9cd0$0e59f953dc9979f734fab05e98ddf88423fd04c660f6c4d6a42cfc8e39e790c4', '26-35', 'Teacher', 'Kochi'),
  ('Rohit Verma', 'rohit@example.com', 'pbkdf2:sha256:600000$90a7854dea37a05d$a6445edcdc183fb709d3503fca00695790015d84bb42f58fd46eaefe90bfb897', '18-25', 'Student', 'Nagpur'),
  ('Sunita Patil', 'sunita@example.com', 'pbkdf2:sha256:600000$3afa99c2846e91a6$abe573d92037b26da86b613f4e0f89221468a4a1720ffaf6c5abacdc36bf0d50', '46-60', 'Homemaker', 'Nashik'),
  ('Imran Khan', 'imran@example.com', 'pbkdf2:sha256:600000$fe2048e3ec4526cf$38106432bb778ef3a35f9a8b3444f026eb2260675a2f0bb4444488a513b39357', '36-45', 'Shopkeeper', 'Bhopal');

INSERT INTO scam_categories (slug, name, icon, summary, what_is_it, how_it_works, warning_signs, example_text, stay_safe, if_targeted, risk_level, display_order) VALUES
  ('phishing', 'Phishing', 'mail', 'Fraudulent emails that imitate trusted organisations to steal your login details.', 'Phishing is an attack where a criminal sends an email that looks like it came from a bank, college, courier company or popular service. The goal is to make you click a link and type your username and password into a copy of the real login page.', 'The attacker registers a look-alike domain and copies the layout of a genuine website. A mass email is sent claiming your account is locked, a payment failed or a document is waiting. The link points to the fake page. Whatever you type is captured instantly and used on the real site before you notice.', 'Sender address does not match the official domain
Generic greeting such as ''Dear Customer''
Urgent deadline or threat of account closure
Link text and actual link destination are different
Spelling and grammar mistakes in an official message
Attachment you never requested', 'From: alerts@secure-bank-verify.example
Subject: Immediate action required - account suspension

Dear Customer, unusual activity was detected on your account. Your netbanking access will be suspended within 24 hours. Verify your identity here: http://secure-bank-verify.example/login

(Fictional example created for training.)', 'Type the website address yourself instead of clicking email links
Check the full sender address, not just the display name
Enable two-factor authentication on important accounts
Never open unexpected attachments
Use a password manager, it will refuse to autofill on a fake domain', 'Disconnect and do not enter anything further
Change the password of the affected account from a different device
Sign out of all active sessions and enable two-factor authentication
Inform the organisation through its official helpline
Report the incident through the official cybercrime reporting channel', 'high', 1),
  ('smishing', 'Smishing', 'message', 'Scam SMS messages carrying malicious links or fake alerts.', 'Smishing is phishing delivered by SMS. Short messages create panic or excitement so you tap a link before thinking, often on a small screen where the full address is hidden.', 'Bulk SMS is sent from unregistered numbers or spoofed sender IDs. The link uses a URL shortener so the real destination is hidden. It leads to a fake KYC form, a fake reward page or a page that installs an app.', 'Message from a random 10-digit mobile number instead of a registered sender ID
Shortened link
Claims about KYC expiry, electricity disconnection or parcel delivery failure
Asks you to install an app from outside the official store
Too-good-to-be-true prizes', 'SMS from +91-98XXXXXX21: ''Dear user, your electricity will be disconnected tonight at 9:30 pm because your previous bill was not updated. Contact officer immediately: 9XXXXXXXXX.''

(Fictional example created for training.)', 'Never tap links in unexpected SMS
Check your bill or booking in the official app instead
Block and report spam senders
Disable installation from unknown sources on your phone
Confirm with the company using the number printed on your bill', 'Do not tap anything else in the message
If you already installed an app, turn off internet and uninstall it
Run a scan and change passwords from a clean device
Inform your bank if any financial app was involved
Keep the message as evidence, then report it', 'high', 2),
  ('vishing', 'Vishing', 'phone', 'Fraudulent phone calls from people pretending to be officials.', 'Vishing is voice phishing. A caller pretends to be from your bank, a telecom operator, a delivery service or even the police, and pressures you into sharing codes or installing remote-access software.', 'The caller already knows a small detail about you, which builds trust. They create urgency, keep you on the line so you cannot verify, and walk you step by step towards reading out an OTP or installing a screen-sharing app.', 'Caller asks for OTP, CVV, PIN or card number
Refuses to let you call back on the official number
Strong urgency and threats of legal action
Asks you to install a remote-access or screen-sharing app
Background call-centre noise with a rehearsed script', 'Caller: ''I am calling from your bank''s fraud department. A transaction of Rs 42,000 is being processed from another city. To block it, please read the six-digit code I have just sent you.''

No genuine bank employee ever needs that code. (Fictional example.)', 'Hang up and call the number printed on your card or official website
Never read out any code received by SMS
Never install apps because a caller told you to
Take your time; genuine institutions allow verification
Register complaints only through official helplines', 'End the call immediately
If you shared a code, call your bank''s official helpline and block the card or account
Check recent transactions and raise a dispute
Uninstall any app the caller made you install
Save the caller number and time, then report the call', 'high', 3),
  ('fake-websites', 'Fake Websites', 'globe', 'Clone sites built to capture logins, payments or personal details.', 'A fake website is a pixel-perfect copy of a genuine shop, bank or government portal hosted on a slightly different address. Everything looks right except the address bar.', 'Attackers buy a look-alike domain, copy the HTML and CSS of the original, and promote it through ads, SMS links or social media. Payments go to the attacker and login details are stored for later misuse.', 'Misspelled or extra words in the domain name
No padlock, or a certificate issued to a different name
Prices far below the market
Only UPI or wallet transfer accepted, no verified gateway
No verifiable address, GST details or working support number', 'A student searched for a discounted laptop and clicked a sponsored link to ''shop-electronics-deal.example''. The site looked like a well-known store but the checkout accepted only a direct UPI transfer to a personal ID.

(Fictional example.)', 'Type addresses manually or use saved bookmarks
Read the domain from right to left before the first single slash
Prefer cash on delivery or verified payment gateways on unfamiliar shops
Search for independent reviews before paying
Check that the padlock certificate is issued to the real company', 'Stop the payment process and close the site
If you paid, contact your bank or payment provider immediately and request a chargeback
Change any password you typed on that site
Take screenshots of the site, the URL and the transaction
Report the website to the official cybercrime portal', 'high', 4),
  ('otp-fraud', 'OTP Fraud', 'key', 'Tricks used to make you reveal the one-time password sent to your phone.', 'An OTP is the last barrier between a criminal and your money. OTP fraud is any technique that convinces you to share, forward or approve that code.', 'The attacker already has your card or account details from a leak or a fake page. When they attempt a transaction, the bank sends the OTP to your phone. They then call, message or send a fake form asking for that code, often disguised as a refund or verification process.', 'Anyone asking for an OTP for any reason
An OTP arriving when you did not request anything
A ''refund'' that requires you to enter a code
Request to forward an SMS to another number
Pressure to hurry before the code expires', 'WhatsApp message: ''Sir, I sent money to your number by mistake. I have requested a reversal. Please share the code you received so the amount comes back to me.''

A reversal never requires your code. (Fictional example.)', 'Treat an OTP like a key to your money and never share it
Read the full OTP message; it states the amount and purpose
If you receive an unrequested OTP, someone is trying to use your account
Use app-based approvals where available
Never forward bank SMS to anyone', 'Do not share anything further
Call the bank helpline and block the card or freeze the account
Change netbanking and UPI credentials
Collect the SMS and call records as evidence
File a report as early as possible; fast reporting improves recovery chances', 'high', 5),
  ('upi-fraud', 'UPI Fraud', 'rupee', 'Collect requests and QR tricks that pull money out of your account.', 'UPI fraud exploits a simple misunderstanding: many people believe entering a UPI PIN is needed to receive money. It never is. A PIN is required only to send money.', 'The fraudster sends a ''collect request'' that looks like a refund or prize. When you approve it and enter your PIN, money leaves your account. Other variants include fake seller profiles on classified sites and ''wrong transfer'' stories.', 'A payment request that claims to be a refund
Anyone asking you to enter your UPI PIN to receive money
Seller who insists on scanning a QR to receive payment
Requests from unknown VPAs with convincing names
Urgency around an expiring offer', 'A seller on a classified app tells a buyer: ''I will send the advance. Just approve the request on your app and enter your PIN to receive it.'' Approving the request debits the buyer instead.

(Fictional example.)', 'Remember: receiving money never needs a PIN
Read the full request screen before approving; it says ''paying''
Disable collect requests from unknown users where your app allows it
Verify the payee name before every transfer
Set a daily transaction limit', 'Decline any pending request and close the app
Raise a dispute in your UPI app and call the bank helpline
Block the UPI ID and the number that contacted you
Save screenshots of the request and transaction reference
Report the fraud through the official channel without delay', 'high', 6),
  ('qr-scams', 'QR Code Scams', 'qr', 'Malicious QR codes that make you pay instead of getting paid.', 'A QR code hides its destination. Criminals exploit this by pasting their own code over a genuine one, or by sending a code that debits rather than credits you.', 'Scanning a payment QR always opens a send-money screen. Fraudsters claim the code is needed to receive a refund or an advance. Other codes open a phishing page or trigger an app download.', 'Anyone sending a QR code so that you can ''receive'' money
Sticker QR pasted over a shop''s original code
QR code in an email, poster or classified ad from an unknown source
App preview showing a different name than the merchant
QR that opens a login page instead of a payment screen', 'A buyer says: ''I am transferring the advance now. Scan the QR I am sending and enter your PIN to accept it.'' Scanning and approving would send money away from the seller.

(Fictional example.)', 'Never scan a QR code to receive money
Check the payee name and amount before confirming
At shops, verify the code belongs to the shop and looks untampered
Avoid scanning codes from posters, emails or strangers
Prefer typing the UPI ID manually for large payments', 'Cancel the transaction before entering your PIN
If money left your account, call the bank immediately
Photograph the QR code and keep the chat as evidence
Inform the shop if a tampered sticker was involved
Report it to the official cybercrime channel', 'high', 7),
  ('fake-customer-care', 'Fake Customer Care', 'headset', 'Fake helpline numbers planted online to trap people looking for support.', 'Criminals publish fake customer-care numbers through search results, business listings, comments and paid ads so that people searching for help reach them instead of the real company.', 'When you call, a convincing agent takes your complaint and then asks you to install a remote-access app ''to process a refund''. Once installed, they can watch your screen and capture credentials, or guide you into a small ''verification'' payment.', 'Support number found in a comment, ad or unofficial listing
Agent asks you to install a screen-sharing app
Refund process that requires you to make a payment first
Personal mobile number instead of a landline or toll-free line
Agent asks for card details or codes', 'After a failed wallet recharge, a user searched for support and called a number from a random listing. The ''agent'' asked them to install a remote-access app and enter Rs 10 to ''verify the account''.

(Fictional example.)', 'Get support numbers only from the official app or website
Never install remote-access tools during a support call
A genuine refund never requires an outgoing payment
Use in-app chat support where available
Verify the company name on any payment screen', 'End the call and uninstall any app you installed
Turn off internet, then change passwords from another device
Inform your bank and block cards if credentials were exposed
Keep call logs and screenshots
Report the fake number to the platform and to cybercrime authorities', 'high', 8),
  ('shopping-scams', 'Online Shopping Scams', 'cart', 'Fake sellers, unreal discounts and products that never arrive.', 'Online shopping scams involve fake stores, fake sellers on social media and fake listings on classified platforms. Payment is taken and the product never arrives or a worthless item is delivered.', 'The seller advertises heavy discounts, insists on advance payment to a personal UPI ID, and communicates only through chat. After payment the account disappears or the buyer receives a substitute item.', 'Discount far below the normal market price
Seller refuses cash on delivery or verified gateways
Only a mobile number and a social media page, no business details
Pressure to pay quickly because ''stock is limited''
No written invoice or return policy', 'An Instagram page advertised branded shoes at a 90 percent discount and asked for full advance payment to a personal UPI ID. After payment the page blocked the buyer.

(Fictional example.)', 'Buy from established platforms with buyer protection
Prefer cash on delivery for unfamiliar sellers
Check reviews, page creation date and seller ratings
Keep invoices and chat records
Never pay an advance to a personal account for a business purchase', 'Stop further payments and keep all chat records
Raise a dispute with your bank or payment provider
Report and report the seller profile to the platform
Leave a factual review to warn others
File a consumer or cybercrime complaint with your evidence', 'medium', 9),
  ('job-scams', 'Job Scams', 'briefcase', 'Fake job offers and work-from-home tasks that charge you money.', 'Job scams target students and job seekers with offers of easy income, promising placements or part-time task work, then extract registration, training or security fees.', 'The scammer contacts you on a messaging app with a simple task and pays a small amount to build trust. Then the tasks require a deposit to ''unlock'' higher earnings, and withdrawals are blocked until more money is paid.', 'Job offer without any interview or verification
Payment demanded for registration, training kit or security deposit
Communication only through a messaging app
Guaranteed high income for very little work
Offer letter with mismatched logos, addresses or email domain', '''Congratulations! You are selected for a work-from-home data entry role paying Rs 25,000 per month. Pay a refundable registration fee of Rs 1,500 to activate your account.''

(Fictional example.)', 'Genuine employers never charge candidates money
Verify the company on its official website and confirm the recruiter
Check the recruiter''s email domain
Never share identity documents before verifying the company
Discuss offers with your placement cell or a trusted adult', 'Stop paying immediately, no matter how much you have already invested
Collect chat records, payment receipts and the offer letter
Report the account to the platform
Inform your bank if you shared account details
File a cybercrime complaint with all evidence', 'medium', 10),
  ('investment-scams', 'Investment Scams', 'chart', 'Guaranteed-return schemes and fake trading platforms.', 'Investment scams promise unusually high and guaranteed returns through trading groups, crypto schemes or private apps. Early payouts are funded by new victims until the scheme collapses.', 'Victims are added to a group where members post screenshots of profits. A ''mentor'' guides them to a private app showing rising balances. Small withdrawals succeed; larger ones require a tax or fee that never ends.', 'Guaranteed or fixed high returns
Pressure to invest quickly or recruit friends
App available only through a direct link, not an official store
Withdrawal blocked until an extra fee is paid
Advisor or platform not registered with the market regulator', 'A group promised 12 percent monthly returns through a private trading app. Balances rose on screen but every withdrawal request demanded a new ''processing tax''.

(Fictional example.)', 'No legitimate investment guarantees returns
Check registration of the platform and advisor with the regulator
Install financial apps only from official app stores
Be cautious of profit screenshots; they are trivially faked
Discuss any large investment with a qualified, independent adviser', 'Stop investing and do not pay any ''release fee''
Export all chat records, transaction IDs and app screenshots
Inform your bank about the beneficiary accounts
Warn others in your circle who may have joined
File a complaint with the cybercrime portal and the market regulator', 'high', 11),
  ('social-media-scams', 'Social Media Scams', 'users', 'Hacked profiles, fake giveaways and impersonation of people you trust.', 'Social media scams use trust between friends. A compromised or cloned account asks for money, votes or verification codes on behalf of someone you know.', 'Attackers take over an account through a phishing link or by asking for a ''verification code''. They then message the contact list with an emergency money request or spread a fake giveaway link.', 'Sudden money request from a friend, with a new payment ID
Request to share a code received on your phone
Giveaway asking for a small fee or personal details
Duplicate profile with the same photos but few friends
Messages written in an unusual style for that person', 'A message from a friend''s account: ''I am stuck and my account is not working. Please transfer Rs 5,000 to this UPI ID, I will return it tonight.'' The account had been taken over.

(Fictional example.)', 'Confirm any money request by calling the person directly
Never share verification codes, even with friends
Enable two-factor authentication on all social accounts
Review connected apps and active sessions periodically
Keep your friend list and personal details private', 'Stop the conversation and call the real person
If your account was taken over, reset the password and remove unknown sessions
Warn your contacts that the account was compromised
Report the fake or hacked profile to the platform
Preserve screenshots and report if money was lost', 'medium', 12);
INSERT INTO scam_examples (category_id, channel, sender, subject, body, is_scam, explanation, warning_signs, difficulty) VALUES
  (1, 'email', 'alerts@secure-bank-verify.example', 'Immediate action required: account suspension', 'Dear Customer,

Unusual activity was detected on your netbanking profile. Your access will be suspended within 24 hours unless you verify your identity.

Verify now: http://secure-bank-verify.example/login', 1, 'This is a phishing email. A bank never asks you to confirm your identity through an emailed link, and the sender domain is not the bank''s real domain.', 'Look-alike sender domain
Urgent 24-hour deadline
Generic greeting
Link goes to an unofficial address', 'easy'),
  (2, 'sms', '+91 98XXXXXX21', NULL, 'Dear user, your electricity connection will be disconnected tonight at 9:30 pm because your previous bill was not updated. Contact officer immediately: 9XXXXXXXXX', 1, 'A genuine utility never warns you from a personal mobile number, and disconnection notices are never issued the same night by SMS.', 'Personal 10-digit sender number
Same-day threat
Asks you to call an unknown number', 'easy'),
  (3, 'sms', 'VM-HDFCBK', NULL, 'Rs 2,450.00 debited from A/c XX4412 on 14-Aug for UPI/P2M/GROCERYMART. Not you? Call 1800-XXX-XXXX printed on your card.', 0, 'This is a normal transaction alert. It reports what happened, does not contain a link, and tells you to use the number printed on your card.', 'No link
No request for information
Directs you to the official number', 'medium'),
  (5, 'whatsapp', '+91 70XXXXXX09', NULL, 'Sir I transferred Rs 5,000 to your number by mistake. I have raised a reversal request. Please share the 6 digit code you just received so the money comes back to me. Please help fast.', 1, 'No refund or reversal ever requires you to share a one-time code. Sharing it would authorise a transaction from your account.', 'Asks for an OTP
Emotional urgency
Unknown number
Story that does not match how banking works', 'easy'),
  (6, 'payment', 'collect request from refund.support@okaxis', NULL, 'PAYMENT REQUEST
refund.support@okaxis is requesting Rs 3,199.00
Note: Order cancellation refund. Approve to receive amount.
[ Enter UPI PIN to proceed ]', 1, 'Receiving money never requires a UPI PIN. This is a collect request that would debit your account.', 'Refund framed as a payment request
Asks for UPI PIN
Unknown VPA', 'medium'),
  (4, 'webpage', 'https://www.arnazon-offers.example/login', NULL, 'Sign in to claim your festival reward
Email or mobile: ______
Password: ______
(No padlock shown in the address bar)', 1, 'The domain is a misspelling of a well-known store and the page has no valid certificate. It exists only to collect passwords.', 'Misspelled domain
No padlock
Reward used as bait', 'easy'),
  (8, 'call', '+91 88XXXXXX34', NULL, 'Hello, I am calling from the wallet support team about your failed recharge. To process the refund, please install the screen-sharing app I am sending and add Rs 10 to verify your account.', 1, 'Genuine support never asks you to install remote-access software, and a refund never requires you to pay first.', 'Remote-access app request
Pay-to-get-refund logic
Unverified support number', 'medium'),
  (9, 'whatsapp', 'Shoe Store Official', NULL, 'FESTIVE CLEARANCE! Branded running shoes worth Rs 6,999 for just Rs 699. Limited stock. Full advance to UPI id shoestore@personalbank. No COD, no returns.', 1, 'A 90 percent discount, advance-only payment to a personal UPI ID and no returns are classic markers of a fake seller.', 'Unrealistic discount
Advance payment only
Personal UPI ID
No returns or invoice', 'easy'),
  (10, 'email', 'hr@globaltech-careers.example', 'Selected for work-from-home role', 'Congratulations! You are selected for a work-from-home data entry role paying Rs 25,000 per month. No interview required. Pay a refundable registration fee of Rs 1,500 to activate your account.', 1, 'Legitimate employers do not select candidates without an interview and never charge a registration fee.', 'No interview
Upfront fee
Unofficial email domain
Unrealistic pay for the role', 'easy'),
  (NULL, 'email', 'noreply@college.edu', 'Semester 5 project submission deadline', 'Dear students, the Community Engagement Project report must be uploaded to the college portal by 30 September. Please log in to the portal from the college website as usual. Contact the department office for help.', 0, 'This is a normal, safe message. It contains no link, no attachment and asks for no credentials.', 'Official domain
No link or attachment
No request for personal data', 'medium'),
  (11, 'whatsapp', 'Trading Mentor Group', NULL, 'Members earned 12% last month. Join our private app and start with Rs 10,000. Guaranteed monthly returns, withdraw anytime. Only 5 seats left today.', 1, 'Guaranteed returns do not exist in any legitimate investment, and a private app outside official stores is a strong warning sign.', 'Guaranteed returns
Artificial scarcity
App outside official stores', 'easy'),
  (12, 'whatsapp', 'Priya (friend)', NULL, 'Hey, my account is having some issue and I am stuck. Please send Rs 5,000 to this new UPI ID, I will return it tonight. Do not call, I am in a meeting.', 1, 'A money request from a friend that discourages a phone call and uses a new payment ID usually means the account was taken over.', 'Asks you not to call
New payment ID
Urgent money request', 'medium'),
  (7, 'payment', 'Shop counter QR', NULL, 'Scan to pay - GROCERY MART
After scanning, your app shows: Paying to GROCERY MART, enter amount.', 0, 'This is a normal merchant payment. The payee name matches the shop and you choose the amount yourself.', 'Payee name matches the shop
You control the amount
No one asked you to scan to receive money', 'hard');

INSERT INTO quiz_questions (quiz_type, category_id, question, explanation) VALUES
  ('pre', 1, 'You receive an email from your bank asking you to click a link and confirm your password. What should you do?', 'Banks never ask for credentials by email. Always reach the site by typing the address yourself.'),
  ('pre', 5, 'Who is allowed to ask you for the OTP sent to your phone?', 'No one. An OTP authorises a transaction and must never be shared with anybody.'),
  ('pre', NULL, 'Which of these is the strongest password practice?', 'Long, unique passphrases with two-factor authentication give the best protection.'),
  ('pre', 6, 'When do you need to enter your UPI PIN?', 'A PIN is required only when money leaves your account. Receiving money never needs a PIN.'),
  ('pre', 4, 'Which website address is most likely to be fake?', 'Look-alike spellings and extra words in the domain are the clearest sign of a clone site.'),
  ('pre', 2, 'An SMS says your KYC will expire today and gives a shortened link. What is the safest action?', 'Verify inside the official app. Shortened links in unsolicited SMS are a standard smishing technique.'),
  ('pre', 3, 'A caller claims to be from the police and demands an immediate payment to avoid arrest. What should you do?', 'Authorities do not demand instant payments over the phone. Disconnect and verify independently.'),
  ('pre', 7, 'Someone sends you a QR code so you can ''receive'' a refund. What does scanning and approving it actually do?', 'Scanning a payment QR always opens a send-money screen. It can only debit you.'),
  ('pre', 8, 'Where should you find a company''s customer-care number?', 'Only official apps, websites and printed documents carry verified support numbers.'),
  ('pre', NULL, 'What is the safest first step if you think you have been scammed?', 'Stop the interaction, then contact your bank immediately and preserve evidence.'),
  ('post', 1, 'An email address shows ''HDFC Bank'' as the display name but the address ends in @secure-alerts.example. What does this indicate?', 'The display name is easy to fake; the actual domain is what matters.'),
  ('post', 5, 'You receive an OTP you did not request. What does it most likely mean?', 'An unrequested OTP means someone already has your credentials and is attempting a transaction.'),
  ('post', 6, 'A buyer sends you a UPI collect request to ''pay you an advance''. What should you do?', 'Approving a collect request sends money away. Decline it and ask for a direct transfer.'),
  ('post', 11, 'An app promises guaranteed 12 percent monthly returns. What is the correct conclusion?', 'Guaranteed high returns are the defining feature of investment fraud.'),
  ('post', 8, 'A support agent asks you to install a screen-sharing app to process your refund. What should you do?', 'Remote-access software gives full visibility of your screen and credentials.'),
  ('post', 4, 'Which check best confirms you are on a genuine website before paying?', 'The domain name and the certificate holder are the reliable checks.'),
  ('post', 10, 'A recruiter offers a job with no interview but asks for a refundable registration fee. What is this?', 'Charging candidates is a hallmark of job fraud.'),
  ('post', 12, 'A friend''s account asks for urgent money and tells you not to call. What should you do?', 'Always verify by voice on a known number before sending money.'),
  ('post', NULL, 'Which of these should you never store or share online?', 'Codes, PINs and card verification values must stay private at all times.'),
  ('post', NULL, 'After being scammed, why is preserving screenshots and transaction IDs important?', 'Evidence supports the bank dispute and the official complaint.');

INSERT INTO quiz_options (question_id, option_text, is_correct) VALUES
  (1, 'Click the link and log in quickly before the deadline', 0),
  (1, 'Ignore the link and open the bank site by typing the address yourself', 1),
  (1, 'Reply to the email asking if it is genuine', 0),
  (1, 'Forward the email to friends to warn them', 0),
  (2, 'Bank employees on a verification call', 0),
  (2, 'Customer-care agents processing a refund', 0),
  (2, 'Nobody, in any situation', 1),
  (2, 'Delivery agents confirming an order', 0),
  (3, 'Using the same strong password on every site', 0),
  (3, 'A long unique passphrase for each account plus two-factor authentication', 1),
  (3, 'Your name and year of birth', 0),
  (3, 'A six-digit number you can remember easily', 0),
  (4, 'Only when sending money', 1),
  (4, 'When receiving money', 0),
  (4, 'Both when sending and receiving', 0),
  (4, 'Whenever the app asks, for security', 0),
  (5, 'https://www.bankofindia.co.in', 0),
  (5, 'https://secure-bankofindia-verify.example', 1),
  (5, 'https://www.irctc.co.in', 0),
  (5, 'https://www.india.gov.in', 0),
  (6, 'Open the link and complete the KYC form', 0),
  (6, 'Reply STOP to the message', 0),
  (6, 'Check your KYC status in the official bank app or branch', 1),
  (6, 'Forward the SMS to family so they can also check', 0),
  (7, 'Pay immediately to avoid trouble', 0),
  (7, 'Disconnect and verify through an official helpline or police station', 1),
  (7, 'Share your account details so they can check', 0),
  (7, 'Install the app they recommend', 0),
  (8, 'Credits money to your account', 0),
  (8, 'Debits money from your account', 1),
  (8, 'Only verifies your identity', 0),
  (8, 'Nothing at all', 0),
  (9, 'Top search results and sponsored ads', 0),
  (9, 'Comments under social media posts', 0),
  (9, 'The official app, official website or your bill', 1),
  (9, 'Any online business directory', 0),
  (10, 'Delete all messages so nobody sees them', 0),
  (10, 'Stop contact, inform your bank at once and keep the evidence', 1),
  (10, 'Keep talking to recover your money', 0),
  (10, 'Wait a few days to see what happens', 0),
  (11, 'It is genuine because the display name matches', 0),
  (11, 'It is likely phishing because the real domain does not match', 1),
  (11, 'It is a technical error by the bank', 0),
  (11, 'It only matters if there is an attachment', 0),
  (12, 'A network glitch', 0),
  (12, 'Someone is trying to access your account or make a payment', 1),
  (12, 'Your bank is testing the system', 0),
  (12, 'You must forward it to the bank', 0),
  (13, 'Approve it and enter your PIN', 0),
  (13, 'Decline it and ask them to transfer directly to your UPI ID', 1),
  (13, 'Share your UPI PIN so they can complete it', 0),
  (13, 'Scan the QR code they send', 0),
  (14, 'It is a good opportunity if friends have profited', 0),
  (14, 'Almost certainly a scam, since guaranteed returns do not exist', 1),
  (14, 'Safe if the app looks professional', 0),
  (14, 'Safe if you invest a small amount', 0),
  (15, 'Install it, support teams often need it', 0),
  (15, 'Refuse, disconnect and contact official support', 1),
  (15, 'Install it but cover your screen', 0),
  (15, 'Ask them to send the app by email instead', 0),
  (16, 'The site looks professional', 0),
  (16, 'The domain is exactly correct and the certificate is issued to the real company', 1),
  (16, 'The site has many product photos', 0),
  (16, 'The prices are very low', 0),
  (17, 'A normal hiring process', 0),
  (17, 'A job scam', 1),
  (17, 'A government scheme', 0),
  (17, 'A training programme', 0),
  (18, 'Send the money, it is your friend', 0),
  (18, 'Call the friend on their known number to verify', 1),
  (18, 'Ask for their password to check', 0),
  (18, 'Send half the amount as a test', 0),
  (19, 'Your favourite colour', 0),
  (19, 'OTPs, PINs and card CVV numbers', 1),
  (19, 'Your city name', 0),
  (19, 'Your college name', 0),
  (20, 'To post them on social media', 0),
  (20, 'They are required evidence for bank disputes and official complaints', 1),
  (20, 'They are not important', 0),
  (20, 'To identify the fraudster yourself', 0);

INSERT INTO videos (title, youtube_id, video_url, description, category_id, thumbnail_url, status) VALUES
  ('How Phishing Attacks Work', 'Rp0vBmZmnAo', 'https://www.youtube.com/watch?v=Rp0vBmZmnAo', 'A clear walkthrough of how a phishing email is crafted and how to recognise the signs before clicking.', 1, 'https://img.youtube.com/vi/Rp0vBmZmnAo/hqdefault.jpg', 'published'),
  ('Spotting a Fake Website', '2Wo3zx1Wxrs', 'https://www.youtube.com/watch?v=2Wo3zx1Wxrs', 'Learn to read a web address correctly and check certificates before entering any login details.', 4, 'https://img.youtube.com/vi/2Wo3zx1Wxrs/hqdefault.jpg', 'published'),
  ('Why You Should Never Share an OTP', 'o0btqyGWIQw', 'https://www.youtube.com/watch?v=o0btqyGWIQw', 'Explains what a one-time password actually authorises and why sharing it hands over your money.', 5, 'https://img.youtube.com/vi/o0btqyGWIQw/hqdefault.jpg', 'published'),
  ('Safe UPI Habits', '6ZlOOOJxLIA', 'https://www.youtube.com/watch?v=6ZlOOOJxLIA', 'Understand collect requests, PIN rules and the settings that reduce UPI fraud risk.', 6, 'https://img.youtube.com/vi/6ZlOOOJxLIA/hqdefault.jpg', 'published'),
  ('Recognising Scam Phone Calls', 'inWWhr5tnEA', 'https://www.youtube.com/watch?v=inWWhr5tnEA', 'The scripts fraudsters use on calls and the exact points where you should hang up.', 3, 'https://img.youtube.com/vi/inWWhr5tnEA/hqdefault.jpg', 'published'),
  ('Safe Browsing Basics', '1pnHIsWTIRw', 'https://www.youtube.com/watch?v=1pnHIsWTIRw', 'Everyday browsing habits that keep your accounts and devices protected.', NULL, 'https://img.youtube.com/vi/1pnHIsWTIRw/hqdefault.jpg', 'published');

INSERT INTO safety_topics (slug, title, icon, summary, tips, display_order) VALUES
  ('password-safety', 'Password Safety', 'key', 'Strong, unique passwords are the foundation of every other protection.', 'Use a passphrase of at least 12 characters made of unrelated words
Never reuse a password across two accounts
Turn on two-factor authentication everywhere it is offered
Store passwords in a reputable password manager, not in a notes app
Change a password immediately if a service reports a breach
Never share a password, even with family, over chat', 1),
  ('otp-safety', 'OTP Safety', 'shield', 'An OTP is a key to your money. It is meant for your eyes only.', 'Never share an OTP with anyone, including people claiming to be bank staff
Read the full OTP message; it states the amount and purpose
An unrequested OTP means someone is trying to use your account
Never forward bank SMS to another number
Disable message previews on the lock screen
Block your card at once if an OTP appears for a payment you did not make', 2),
  ('upi-safety', 'UPI Safety', 'rupee', 'Most UPI fraud depends on one myth: that a PIN is needed to receive money.', 'A UPI PIN is required only to send money, never to receive it
Read the request screen fully before approving
Verify the payee name before every transfer
Set a sensible daily transaction limit
Disable collect requests from unknown users if your app allows it
Check your statement weekly', 3),
  ('mobile-safety', 'Mobile Safety', 'phone', 'Your phone holds your banking, identity and contacts. Treat it accordingly.', 'Install apps only from the official app store
Review app permissions and remove what is not needed
Keep the operating system and apps updated
Use a screen lock and biometric unlock
Never install remote-access apps because a caller asked you to
Enable remote lock and wipe in case of theft', 4),
  ('email-safety', 'Email Safety', 'mail', 'Email remains the most common delivery route for fraud.', 'Check the full sender address, not the display name
Hover over links to preview the destination before clicking
Never open unexpected attachments, especially archives and macros
Mark suspicious mail as phishing rather than just deleting it
Use a separate email for banking and important accounts
Turn on two-factor authentication for your mailbox', 5),
  ('safe-browsing', 'Safe Browsing', 'globe', 'A few seconds spent reading the address bar prevents most clone-site losses.', 'Type important addresses manually or use bookmarks
Read the domain from right to left before the first single slash
Check the padlock and the certificate holder before paying
Avoid entering credentials on public or shared computers
Use a trusted network for financial transactions
Keep your browser updated and remove unknown extensions', 6),
  ('social-media-safety', 'Social Media Safety', 'users', 'Trust between friends is exactly what social scams exploit.', 'Confirm money requests by calling the person on a known number
Enable two-factor authentication on all social accounts
Keep personal details, travel plans and documents off public profiles
Review logged-in devices and connected apps regularly
Be cautious of giveaways that ask for a fee or personal data
Report cloned profiles immediately', 7),
  ('shopping-safety', 'Online Shopping Safety', 'cart', 'Buyer protection exists on real platforms. Use it.', 'Prefer established platforms with dispute resolution
Choose cash on delivery for unfamiliar sellers
Never pay an advance to a personal UPI ID for a business purchase
Read recent reviews and check the seller''s history
Keep invoices, order IDs and chat records
Be suspicious of discounts far below market price', 8),
  ('call-safety', 'Call Safety', 'headset', 'Urgency on a phone call is a pressure tactic, not a genuine emergency.', 'Hang up and call back on the number printed on your card or bill
Never share codes, PINs or card details on a call
Do not install any app during a support call
Take your time; genuine institutions allow verification
Record or note the number, time and claims made
Block and report repeat fraud callers', 9);

INSERT INTO learning_resources (title, resource_type, category_id, summary, content) VALUES
  ('Ten-Point Personal Cyber Safety Checklist', 'checklist', NULL, 'A printable checklist covering passwords, OTPs, payments, devices and reporting.', '1. Every important account uses a unique passphrase.
2. Two-factor authentication is enabled on email, banking and social accounts.
3. No OTP, PIN or CVV has ever been shared with anyone.
4. Bank and payment apps were installed only from the official app store.
5. A daily transaction limit is set on UPI and cards.
6. Website addresses are typed or opened from bookmarks, never from SMS links.
7. Unknown apps and unused permissions have been removed from the phone.
8. Support numbers are taken only from official apps, websites or bills.
9. Account statements are checked at least once a week.
10. Official helpline and cybercrime reporting details are saved in advance.'),
  ('How to Read a Web Address Correctly', 'article', 4, 'The single skill that prevents most fake-website losses, explained step by step.', 'A web address is read from right to left. Find the first single slash after the domain, then look at the two words immediately before it. In https://accounts.example-bank.co.in/login, the real owner is example-bank.co.in. Everything before it, such as accounts., is chosen freely by whoever owns the domain.

This is why example-bank.secure-login.example is NOT the bank: the real owner is secure-login.example.

Checklist before you type a password:
- Is the domain spelled exactly right, with no extra words or hyphens?
- Is there a padlock, and is the certificate issued to the company you expect?
- Did you arrive here by typing the address or from a link someone sent?

If you arrived from a link and the domain is unfamiliar, close the page and start again from your bookmark.'),
  ('What To Do In The First Hour After A Scam', 'article', NULL, 'Fast, ordered actions that give you the best chance of limiting the damage.', 'The first hour matters more than anything else.

1. Stop. Do not send another rupee and do not continue the conversation, even to argue.
2. Call your bank or payment provider on the number printed on your card and ask them to block the card or freeze the account.
3. Change the passwords of affected accounts from a different, clean device, and sign out of all sessions.
4. Remove any app the fraudster asked you to install, then turn the device''s internet back on only after removing it.
5. Collect evidence: screenshots of chats, the sender number, transaction IDs, dates and amounts.
6. File a complaint through the official cybercrime reporting channel in your country and keep the acknowledgement number.

Tell someone you trust. Embarrassment is what keeps most cases unreported, and delay is what makes recovery harder.'),
  ('Family Awareness Poster: Never Share Your OTP', 'poster', 5, 'A single-message poster suitable for printing and displaying at home, hostels or offices.', 'HEADLINE: Nobody needs your OTP. Nobody.

SUPPORTING LINES:
- Your bank will never ask for it.
- Customer care will never ask for it.
- A refund never requires it.
- A friend in trouble never needs it.

FOOTER: If someone asks for your OTP, the call is a scam. Hang up and call your bank on the number printed on your card.'),
  ('Anatomy of a Phishing Email', 'infographic', 1, 'A visual breakdown of the six parts of a phishing email and what to inspect in each.', '1. SENDER: display name looks right, the domain does not. Always expand the address.
2. GREETING: ''Dear Customer'' instead of your name means it was sent to thousands.
3. URGENCY: a 24-hour deadline exists to stop you from thinking.
4. LINK: the visible text and the real destination differ. Hover before clicking.
5. FORM: a login form inside or immediately behind an email is always suspicious.
6. FOOTER: copied logos and a mismatched or missing physical address.

If two or more of these appear together, treat the message as phishing and verify through the official app.'),
  ('Safe Digital Payment Habits', 'tip', 6, 'Six habits that remove most everyday payment risk.', '1. Never enter a PIN to receive money.
2. Verify the payee name on the confirmation screen every single time.
3. Set daily limits so a single mistake cannot empty an account.
4. Keep a low-balance account for online payments.
5. Turn on instant transaction alerts.
6. Reconcile your statement weekly and dispute anything unfamiliar immediately.');

INSERT INTO quiz_attempts (user_id, quiz_type, score, total, percentage, awareness_level, attempted_at) VALUES
  (1,'pre',4,10,40,'Needs Improvement','2026-08-02 10:15:00'),
  (1,'post',9,10,90,'Excellent','2026-08-09 17:40:00'),
  (2,'pre',5,10,50,'Moderate','2026-08-03 11:05:00'),
  (2,'post',9,10,90,'Excellent','2026-08-11 09:20:00'),
  (3,'pre',3,10,30,'Needs Improvement','2026-08-04 15:45:00'),
  (3,'post',8,10,80,'Good','2026-08-12 19:10:00'),
  (4,'pre',2,10,20,'High Risk','2026-08-05 12:00:00'),
  (4,'post',7,10,70,'Good','2026-08-13 18:05:00'),
  (5,'pre',6,10,60,'Moderate','2026-08-06 14:30:00'),
  (5,'post',9,10,90,'Excellent','2026-08-14 20:25:00'),
  (2,'spot',11,13,85,'Excellent','2026-08-10 16:00:00'),
  (3,'spot',9,13,69,'Moderate','2026-08-11 13:35:00');

INSERT INTO feedback (user_id, name, email, rating, message, suggestions) VALUES
  (1,'Aarav Sharma','aarav@example.com',5,'The Spot the Scam section made the warning signs obvious. I recognised a smishing SMS the next day and ignored it.','Add more examples in regional languages.'),
  (2,'Meera Nair','meera@example.com',5,'I used the awareness videos and the checklist in a session with senior citizens in our locality. The material was easy to explain.','A printable one-page version of each checklist would help field sessions.'),
  (4,'Sunita Patil',NULL,4,'I did not know that a PIN is never needed to receive money. That single point was worth the whole session.','Please keep the language simple in the investment section as well.'),
  (NULL,'Workshop Participant',NULL,4,'The pre-test and post-test comparison clearly showed how much we improved during the workshop.','Allow exporting the result as a certificate.');

INSERT INTO user_progress (user_id, category_id) VALUES
  (1,1),(1,2),(1,5),(1,6),(2,1),(2,4),(2,5),(2,6),(2,7),(3,1),(3,3),(4,5),(4,6),(5,1),(5,9);
