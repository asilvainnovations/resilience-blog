import sgMail from '@sendgrid/mail'
import { supabase } from './supabase.js'

sgMail.setApiKey(process.env.SENDGRID_API_KEY)

export const email = {
  // Queue email for sending
  queue: async ({ template, to, variables, metadata = {} }) => {
    // Get template from database
    const { data: templateData } = await supabase
      .from('email_templates')
      .select('*')
      .eq('name', template)
      .single()
    
    if (!templateData) throw new Error('Template not found')
    
    // Replace variables in template
    const subject = replaceVariables(templateData.subject_template, variables)
    const html = replaceVariables(templateData.body_template_html, variables)
    const text = templateData.body_template_text 
      ? replaceVariables(templateData.body_template_text, variables)
      : null
    
    // Log to database
    const { data: logEntry } = await supabase
      .from('email_logs')
      .insert({
        template_id: templateData.id,
        to_email: to.email,
        to_name: to.name,
        subject,
        body_html: html,
        body_text: text,
        status: 'queued',
        metadata
      })
      .select()
      .single()
    
    return logEntry
  },

  // Process queued emails (called by cron job)
  processQueue: async (batchSize = 10) => {
    const { data: queuedEmails } = await supabase
      .from('email_logs')
      .select('*')
      .eq('status', 'queued')
      .limit(batchSize)
    
    for (const email of queuedEmails) {
      try {
        await sgMail.send({
          to: { email: email.to_email, name: email.to_name },
          from: {
            email: process.env.FROM_EMAIL,
            name: process.env.FROM_NAME
          },
          subject: email.subject,
          html: email.body_html,
          text: email.body_text,
          customArgs: {
            email_log_id: email.id
          }
        })
        
        // Update status
        await supabase
          .from('email_logs')
          .update({ 
            status: 'sent', 
            sent_at: new Date().toISOString() 
          })
          .eq('id', email.id)
          
      } catch (error) {
        await supabase
          .from('email_logs')
          .update({ 
            status: 'failed',
            metadata: { ...email.metadata, error: error.message }
          })
          .eq('id', email.id)
      }
    }
  },

  // Webhook handler for SendGrid events
  handleWebhook: async (events) => {
    for (const event of events) {
      const emailLogId = event.email_log_id || event.custom_args?.email_log_id
      
      if (!emailLogId) continue
      
      // Log event
      await supabase.from('email_events').insert({
        email_log_id: emailLogId,
        event_type: event.event,
        provider_event_id: event.sg_event_id,
        event_data: event,
        occurred_at: new Date(event.timestamp * 1000).toISOString()
      })
      
      // Update email log status based on event
      const statusMap = {
        'delivered': 'delivered',
        'open': 'opened',
        'click': 'clicked',
        'bounce': 'bounced',
        'dropped': 'failed',
        'spamreport': 'spam'
      }
      
      if (statusMap[event.event]) {
        const updateData = { status: statusMap[event.event] }
        
        if (event.event === 'delivered') {
          updateData.delivered_at = new Date().toISOString()
        } else if (event.event === 'open') {
          updateData.opened_at = new Date().toISOString()
        } else if (event.event === 'click') {
          updateData.clicked_at = new Date().toISOString()
        } else if (event.event === 'bounce') {
          updateData.bounce_reason = event.reason
        }
        
        await supabase
          .from('email_logs')
          .update(updateData)
          .eq('id', emailLogId)
      }
    }
  }
}

function replaceVariables(template, variables) {
  return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    return variables[key] !== undefined ? variables[key] : match
  })
}
