from datetime import date, timedelta
import sys
import csv
import imaplib
import getpass
import email
import zipfile
from StringIO import StringIO

if __name__ == "__main__":
    account = raw_input('Please enter the email address you want to retrieve the zipped csvs from: ') 
    password = getpass.getpass('Please enter the password for your gmail IMAP account: ', sys.stdout)
    delete = True 
    mailbox = imaplib.IMAP4_SSL('imap.gmail.com', 993)
    mailbox.login(account, password)
    status, count = mailbox.select('Inbox')
    the_date = (date.today() - timedelta(days=7)).strftime('%d-%b-%Y') 
    result, data = mailbox.uid('search', None, '(SENTSINCE {date} HEADER Subject "Commission Junction Report Data Delivery")'.format(date=the_date))
    fieldnames = ["Date","Event_Date","Action_Name","ID","Action_Type","Source","Status","Corrected","Sale_Amount","Order_Discount","Commission","Website_ID","Website_Name","Ad_ID","Advertiser_ID","Advertiser_Name","SID","Order_ID","Click_Date","Action_ID","Ad_Owner_Advertiser_ID","Correction_Reason"]
    result = StringIO()
    cj_csv = csv.DictWriter(result, fieldnames)
    filenames = ["cj_txn_report-1.txt", "cj_txn_report-2.txt", "cj_txn_report-3.txt", "cj_txn_report-4.txt", "cj_txn_report-5.txt", "cj_txn_report-6.txt", "cj_txn_report-7.txt", "cj_txn_report-8.txt"]
    for uid in data[0].split():
        resp, data = mailbox.uid('fetch', uid, '(RFC822)')
        email_body = data[0][1]
        mail = email.message_from_string(email_body)
        if mail.get_content_maintype() != 'multipart':
            pass
        for part in mail.walk():
            if part.get_content_maintype() == 'multipart':
                continue
            if part.get('Content-Disposition') is None:
                continue
            zip_data = StringIO()
            zip_data.write(part.get_payload(decode=True))
            zip = zipfile.ZipFile(zip_data)
        for filename in filenames:
            try:
                zip_contents = zip.open(filename)
            except:
                continue
            reader = csv.DictReader(zip_contents)
            for line in reader:
                cj_csv.writerow(line)
        if delete:
            mailbox.uid('store', uid, '+FLAGS', r'(\Deleted)') 
    combined_csv = open('combined_cj_csv.csv', 'wb')
    combined_csv.write(','.join(fieldnames))
    combined_csv.write('\n')
    combined_csv.write(result.getvalue())        
    mailbox.logout()
