
from airflow.providers.smtp.notifications.smtp import SmtpNotifier


def email_on_failure(email_to):
    
    return SmtpNotifier(
        to=email_to,
        subject="[FAILED] Airflow | {{ ti.dag_id }}.{{ ti.task_id }}",
        html_content="""
        <div style="margin:0;padding:30px 12px;background:#f1f5f9;
                    font-family:Arial,Helvetica,sans-serif;">

        <table role="presentation" cellpadding="0" cellspacing="0"
                style="width:100%;max-width:620px;margin:auto;
                        background:#ffffff;border-radius:12px;
                        border:1px solid #e2e8f0;">

            <!-- HEADER -->
            <tr>
            <td style="padding:28px;background:#b91c1c;color:#ffffff;">
                <div style="font-size:13px;font-weight:bold;
                            letter-spacing:2px;">
                APACHE AIRFLOW
                </div>
                <h1 style="margin:14px 0 6px;font-size:28px;">
                Task Failed
                </h1>
                <p style="margin:0;color:#fee2e2;font-size:14px;">
                A workflow task encountered an error.
                </p>
            </td>
            </tr>

            <!-- DETAILS -->
            <tr>
            <td style="padding:28px;">
                <h3 style="margin:0 0 18px;color:#334155;">
                Execution Details
                </h3>

                <table cellpadding="9" cellspacing="0"
                    style="width:100%;font-size:14px;
                            border-collapse:collapse;
                            overflow-wrap:anywhere;">
                <tr style="background:#f8fafc;">
                    <td style="color:#64748b;width:110px;">DAG ID</td>
                    <td><b>{{ ti.dag_id | e }}</b></td>
                </tr>
                <tr>
                    <td style="color:#64748b;">Task ID</td>
                    <td><b>{{ ti.task_id | e }}</b></td>
                </tr>
                <tr style="background:#f8fafc;">
                    <td style="color:#64748b;">Run ID</td>
                    <td>{{ run_id | e }}</td>
                </tr>
                <tr>
                    <td style="color:#64748b;">Attempt</td>
                    <td>{{ ti.try_number }}</td>
                </tr>
                </table>

                <!-- ERROR -->
                <h3 style="margin:28px 0 12px;color:#991b1b;">
                Error Message
                </h3>

                <div style="padding:18px;background:#fef2f2;
                            border-left:4px solid #dc2626;
                            border-radius:6px;">
                <div style="font-family:Consolas,monospace;
                            font-size:13px;line-height:1.7;
                            color:#7f1d1d;
                            white-space:pre-wrap;
                            overflow-wrap:anywhere;">{% if exception %}{{ exception | string | e }}{% else %}Error details unavailable. Please check task logs.{% endif %}</div>
                </div>

                <!-- LOG BUTTON -->
                <table role="presentation" cellpadding="0"
                    cellspacing="0" style="margin-top:26px;">
                <tr>
                    <td bgcolor="#2563eb"
                        style="border-radius:7px;padding:14px 24px;">
                    <a href="{{ ti.log_url | e }}"
                        style="color:#ffffff;
                                text-decoration:none;
                                font-weight:bold;font-size:14px;">
                        View Task Logs &#8594;
                    </a>
                    </td>
                </tr>
                </table>

                <p style="margin:24px 0 0;font-size:12px;
                        color:#94a3b8;">
                This is an automated notification
                from Apache Airflow.
                </p>
            </td>
            </tr>
        </table>
        </div>
        """,
    )