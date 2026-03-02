import { supabase } from '@/integrations/supabase/client';

// Extend Supabase types with additional fields used in the app
export interface SiteSettings {
  id: string;
  user_id: string;
  logo_url: string | null;
  background_urls: string[] | null;
  primary_color: string | null;
  secondary_color: string | null;
  delivery_fee: number | null;
  min_order_value: number | null;
  site_name: string | null;
  store_id: string | null;
  created_at: string;
  updated_at: string;
  // Legacy fields
  background_url?: string;
  site_title?: string;
}

export const siteSettingsService = {
  async get(): Promise<SiteSettings | null> {
    const { data, error } = await supabase
      .from('site_settings')
      .select('*')
      .maybeSingle();
    
    if (error) {
      console.error('Error fetching site settings:', error);
      return null;
    }
    
    return data;
  },

  async update(settings: Partial<SiteSettings>): Promise<SiteSettings | null> {
    const existingSettings = await this.get();
    
    if (!existingSettings) {
      // Create initial record if none exists
      // Get current user ID
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('Usuário não autenticado');
      }
      
      const { data, error } = await supabase
        .from('site_settings')
        .insert({
          user_id: user.id,
          logo_url: settings.logo_url || null,
          background_urls: settings.background_urls || null,
          primary_color: settings.primary_color || null,
          secondary_color: settings.secondary_color || null,
          delivery_fee: settings.delivery_fee ?? 0,
          min_order_value: settings.min_order_value ?? 0,
          site_name: settings.site_name || null,
          store_id: settings.store_id || null
        })
        .select()
        .maybeSingle();
      
      if (error) {
        console.error('Error creating site settings:', error);
        throw error;
      }
      
      return data;
    }

    // Only update fields that exist in the database
    const dbSettings: any = {};
    if ('logo_url' in settings) dbSettings.logo_url = settings.logo_url;
    if ('background_urls' in settings) dbSettings.background_urls = settings.background_urls;
    if ('primary_color' in settings) dbSettings.primary_color = settings.primary_color;
    if ('secondary_color' in settings) dbSettings.secondary_color = settings.secondary_color;
    if ('delivery_fee' in settings) dbSettings.delivery_fee = settings.delivery_fee;
    if ('min_order_value' in settings) dbSettings.min_order_value = settings.min_order_value;
    if ('site_name' in settings) dbSettings.site_name = settings.site_name;
    if ('store_id' in settings) dbSettings.store_id = settings.store_id;

    const { data, error } = await supabase
      .from('site_settings')
      .update(dbSettings)
      .eq('id', existingSettings.id)
      .select()
      .maybeSingle();
    
    if (error) {
      console.error('Error updating site settings:', error);
      throw error;
    }
    
    return data;
  },

  async uploadImage(file: File, type: 'logo' | 'background'): Promise<string> {
    console.log('uploadImage called with:', { fileName: file.name, fileSize: file.size, type });
    const fileExt = file.name.split('.').pop();
    const fileName = `${type}-${Date.now()}.${fileExt}`;
    const filePath = `${fileName}`;
    console.log('Generated file path:', filePath);

    console.log('Attempting to upload to Supabase storage...');
    const { error: uploadError } = await supabase.storage
      .from('site-assets')
      .upload(filePath, file, { upsert: true, contentType: file.type, cacheControl: '3600' });

    if (uploadError) {
      console.error('Error uploading file:', uploadError);
      console.error('Upload error details:', {
        message: uploadError.message,
        name: uploadError.name
      });
      throw uploadError;
    }

    console.log('File uploaded successfully, getting public URL...');
    const { data } = supabase.storage
      .from('site-assets')
      .getPublicUrl(filePath);

    console.log('Public URL generated:', data.publicUrl);
    return data.publicUrl;
  },

  async deleteImage(url: string): Promise<void> {
    if (!url || !url.includes('site-assets')) return;
    
    const fileName = url.split('/').pop();
    if (!fileName) return;

    const { error } = await supabase.storage
      .from('site-assets')
      .remove([fileName]);

    if (error) {
      console.error('Error deleting file:', error);
    }
  }
};