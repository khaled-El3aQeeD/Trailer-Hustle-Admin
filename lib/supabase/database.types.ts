export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      admin_notifications: {
        Row: {
          createdAt: string
          deletedAt: string | null
          description: string
          email: string
          id: number
          is_read: number
          name: string
          notification_type: number
          title: string
          type: number
          updatedAt: string
          user_id: number
        }
        Insert: {
          createdAt: string
          deletedAt?: string | null
          description: string
          email: string
          id?: number
          is_read: number
          name: string
          notification_type: number
          title: string
          type: number
          updatedAt: string
          user_id: number
        }
        Update: {
          createdAt?: string
          deletedAt?: string | null
          description?: string
          email?: string
          id?: number
          is_read?: number
          name?: string
          notification_type?: number
          title?: string
          type?: number
          updatedAt?: string
          user_id?: number
        }
        Relationships: []
      }
      adminNotifications: {
        Row: {
          createdAt: string
          description: string | null
          email: string | null
          id: number
          is_read: number
          notification_type: number
          title: string
          updatedAt: string
          user_id: number | null
        }
        Insert: {
          createdAt: string
          description?: string | null
          email?: string | null
          id?: number
          is_read: number
          notification_type: number
          title: string
          updatedAt: string
          user_id?: number | null
        }
        Update: {
          createdAt?: string
          description?: string | null
          email?: string | null
          id?: number
          is_read?: number
          notification_type?: number
          title?: string
          updatedAt?: string
          user_id?: number | null
        }
        Relationships: []
      }
      brandModel: {
        Row: {
          brandId: number
          createdAt: string
          id: number
          modelName: string
          updatedAt: string
        }
        Insert: {
          brandId: number
          createdAt: string
          id?: number
          modelName: string
          updatedAt: string
        }
        Update: {
          brandId?: number
          createdAt?: string
          id?: number
          modelName?: string
          updatedAt?: string
        }
        Relationships: []
      }
      Brands: {
        Row: {
          added_by: number | null
          createdAt: string
          deletedAt: string | null
          id: number
          is_published: number
          title: string
          updatedAt: string
        }
        Insert: {
          added_by?: number | null
          createdAt: string
          deletedAt?: string | null
          id?: number
          is_published: number
          title: string
          updatedAt: string
        }
        Update: {
          added_by?: number | null
          createdAt?: string
          deletedAt?: string | null
          id?: number
          is_published?: number
          title?: string
          updatedAt?: string
        }
        Relationships: []
      }
      Business: {
        Row: {
          category_id: number | null
          complete_profile: number | null
          country_code: string | null
          createdAt: string
          deletedAt: string | null
          description: string | null
          display_name: string | null
          email: string | null
          facebook: string | null
          id: number
          image: string | null
          instagram: string | null
          is_featured: number | null
          is_verify: number | null
          isRequest: number
          latitude: number | null
          location: string | null
          loginTime: number
          longitude: number | null
          mobile_number: string | null
          notification_status: number | null
          otp: number | null
          status: number | null
          tiktok: string | null
          twitter: string | null
          updatedAt: string
          website: string | null
        }
        Insert: {
          category_id?: number | null
          complete_profile?: number | null
          country_code?: string | null
          createdAt: string
          deletedAt?: string | null
          description?: string | null
          display_name?: string | null
          email?: string | null
          facebook?: string | null
          id?: number
          image?: string | null
          instagram?: string | null
          is_featured?: number | null
          is_verify?: number | null
          isRequest: number
          latitude?: number | null
          location?: string | null
          loginTime: number
          longitude?: number | null
          mobile_number?: string | null
          notification_status?: number | null
          otp?: number | null
          status?: number | null
          tiktok?: string | null
          twitter?: string | null
          updatedAt: string
          website?: string | null
        }
        Update: {
          category_id?: number | null
          complete_profile?: number | null
          country_code?: string | null
          createdAt?: string
          deletedAt?: string | null
          description?: string | null
          display_name?: string | null
          email?: string | null
          facebook?: string | null
          id?: number
          image?: string | null
          instagram?: string | null
          is_featured?: number | null
          is_verify?: number | null
          isRequest?: number
          latitude?: number | null
          location?: string | null
          loginTime?: number
          longitude?: number | null
          mobile_number?: string | null
          notification_status?: number | null
          otp?: number | null
          status?: number | null
          tiktok?: string | null
          twitter?: string | null
          updatedAt?: string
          website?: string | null
        }
        Relationships: []
      }
      business_categories: {
        Row: {
          business_id: number
          category_id: number
          created_at: string | null
          id: number
          is_primary: boolean | null
        }
        Insert: {
          business_id: number
          category_id: number
          created_at?: string | null
          id?: number
          is_primary?: boolean | null
        }
        Update: {
          business_id?: number
          category_id?: number
          created_at?: string | null
          id?: number
          is_primary?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "business_categories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "Businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "Categories"
            referencedColumns: ["id"]
          },
        ]
      }
      Businesses: {
        Row: {
          business_contact_number: string
          business_country_code: string
          category_id: number | null
          color: string
          complete_profile: number
          contact_email: string | null
          country_code: number
          createdAt: string | null
          deletedAt: string | null
          description: string | null
          device_token: string | null
          device_type: number | null
          display_name: string
          email: string | null
          facebook: string | null
          id: number
          image: string
          instagram: string | null
          is_featured: number
          is_verify: number
          isRequest: number
          latitude: number | null
          location: string
          loginTime: number
          longitude: number | null
          mobile_number: string
          notification_status: number
          otp: string | null
          profile_image: string | null
          regularCityState: string
          regularPreciseLocation: number
          roomId: number
          social_id: string | null
          social_type: number
          status: number
          subscriptionEndDate: string
          subscriptionStatus: string
          subscriptionType: number
          tiktok: string | null
          twitter: string | null
          updatedAt: string | null
          website: string
          youtube: string | null
          zip_code: string | null
        }
        Insert: {
          business_contact_number: string
          business_country_code: string
          category_id?: number | null
          color: string
          complete_profile: number
          contact_email?: string | null
          country_code: number
          createdAt?: string | null
          deletedAt?: string | null
          description?: string | null
          device_token?: string | null
          device_type?: number | null
          display_name: string
          email?: string | null
          facebook?: string | null
          id?: number
          image: string
          instagram?: string | null
          is_featured: number
          is_verify: number
          isRequest: number
          latitude?: number | null
          location: string
          loginTime: number
          longitude?: number | null
          mobile_number: string
          notification_status: number
          otp?: string | null
          profile_image?: string | null
          regularCityState: string
          regularPreciseLocation: number
          roomId: number
          social_id?: string | null
          social_type: number
          status: number
          subscriptionEndDate: string
          subscriptionStatus: string
          subscriptionType: number
          tiktok?: string | null
          twitter?: string | null
          updatedAt?: string | null
          website: string
          youtube?: string | null
          zip_code?: string | null
        }
        Update: {
          business_contact_number?: string
          business_country_code?: string
          category_id?: number | null
          color?: string
          complete_profile?: number
          contact_email?: string | null
          country_code?: number
          createdAt?: string | null
          deletedAt?: string | null
          description?: string | null
          device_token?: string | null
          device_type?: number | null
          display_name?: string
          email?: string | null
          facebook?: string | null
          id?: number
          image?: string
          instagram?: string | null
          is_featured?: number
          is_verify?: number
          isRequest?: number
          latitude?: number | null
          location?: string
          loginTime?: number
          longitude?: number | null
          mobile_number?: string
          notification_status?: number
          otp?: string | null
          profile_image?: string | null
          regularCityState?: string
          regularPreciseLocation?: number
          roomId?: number
          social_id?: string | null
          social_type?: number
          status?: number
          subscriptionEndDate?: string
          subscriptionStatus?: string
          subscriptionType?: number
          tiktok?: string | null
          twitter?: string | null
          updatedAt?: string | null
          website?: string
          youtube?: string | null
          zip_code?: string | null
        }
        Relationships: []
      }
      businesssimages: {
        Row: {
          businessId: number
          createdAt: string
          deletedAt: string | null
          id: number
          image: string
          updatedAt: string
        }
        Insert: {
          businessId: number
          createdAt: string
          deletedAt?: string | null
          id?: number
          image: string
          updatedAt: string
        }
        Update: {
          businessId?: number
          createdAt?: string
          deletedAt?: string | null
          id?: number
          image?: string
          updatedAt?: string
        }
        Relationships: []
      }
      Categories: {
        Row: {
          color: string
          createdAt: string
          id: number
          image: string | null
          name: string
          position: number
          status: number
          updatedAt: string
        }
        Insert: {
          color: string
          createdAt: string
          id?: number
          image?: string | null
          name: string
          position: number
          status: number
          updatedAt: string
        }
        Update: {
          color?: string
          createdAt?: string
          id?: number
          image?: string | null
          name?: string
          position?: number
          status?: number
          updatedAt?: string
        }
        Relationships: []
      }
      chat_reports: {
        Row: {
          comment: string
          createdAt: string
          groupId: number
          id: number
          updatedAt: string
          user2Id: number
          userId: number
        }
        Insert: {
          comment: string
          createdAt: string
          groupId: number
          id?: number
          updatedAt: string
          user2Id: number
          userId: number
        }
        Update: {
          comment?: string
          createdAt?: string
          groupId?: number
          id?: number
          updatedAt?: string
          user2Id?: number
          userId?: number
        }
        Relationships: []
      }
      chatConstants: {
        Row: {
          addressId: string
          createdAt: string
          deletedLastMessageId: number | null
          groupId: string | null
          id: number
          lastMessageId: string
          receiverId: string | null
          senderId: string
          updatedAt: string
        }
        Insert: {
          addressId: string
          createdAt: string
          deletedLastMessageId?: number | null
          groupId?: string | null
          id?: number
          lastMessageId: string
          receiverId?: string | null
          senderId: string
          updatedAt: string
        }
        Update: {
          addressId?: string
          createdAt?: string
          deletedLastMessageId?: number | null
          groupId?: string | null
          id?: number
          lastMessageId?: string
          receiverId?: string | null
          senderId?: string
          updatedAt?: string
        }
        Relationships: []
      }
      Cms: {
        Row: {
          createdAt: string
          description: string | null
          id: number
          title: string | null
          type: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          description?: string | null
          id?: number
          title?: string | null
          type: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          description?: string | null
          id?: number
          title?: string | null
          type?: number
          updatedAt?: string
        }
        Relationships: []
      }
      ContactUs: {
        Row: {
          country_code: string
          createdAt: string
          description: string
          email: string
          id: number
          name: string
          phoneNumber: string
          updatedAt: string
          userId: number
        }
        Insert: {
          country_code: string
          createdAt: string
          description: string
          email: string
          id?: number
          name: string
          phoneNumber: string
          updatedAt: string
          userId: number
        }
        Update: {
          country_code?: string
          createdAt?: string
          description?: string
          email?: string
          id?: number
          name?: string
          phoneNumber?: string
          updatedAt?: string
          userId?: number
        }
        Relationships: []
      }
      declarewinners: {
        Row: {
          businessId: number
          createdAt: string
          giveawayId: number
          id: number
          status: number | null
          updatedAt: string
        }
        Insert: {
          businessId: number
          createdAt: string
          giveawayId: number
          id?: number
          status?: number | null
          updatedAt: string
        }
        Update: {
          businessId?: number
          createdAt?: string
          giveawayId?: number
          id?: number
          status?: number | null
          updatedAt?: string
        }
        Relationships: []
      }
      deleted_message: {
        Row: {
          createdAt: string
          groupId: number
          id: number
          messageId: number
          updatedAt: string
          userId: number
        }
        Insert: {
          createdAt: string
          groupId: number
          id?: number
          messageId: number
          updatedAt: string
          userId: number
        }
        Update: {
          createdAt?: string
          groupId?: number
          id?: number
          messageId?: number
          updatedAt?: string
          userId?: number
        }
        Relationships: []
      }
      deleted_messages: {
        Row: {
          createdAt: string
          groupId: number
          id: number
          messageId: number
          updatedAt: string
          userId: number
        }
        Insert: {
          createdAt: string
          groupId: number
          id?: number
          messageId: number
          updatedAt: string
          userId: number
        }
        Update: {
          createdAt?: string
          groupId?: number
          id?: number
          messageId?: number
          updatedAt?: string
          userId?: number
        }
        Relationships: []
      }
      favoriteBussiness: {
        Row: {
          bussinessId: number
          createdAt: string
          favorite: number
          id: number
          updatedAt: string
          userId: number
        }
        Insert: {
          bussinessId: number
          createdAt: string
          favorite: number
          id?: number
          updatedAt: string
          userId: number
        }
        Update: {
          bussinessId?: number
          createdAt?: string
          favorite?: number
          id?: number
          updatedAt?: string
          userId?: number
        }
        Relationships: []
      }
      featuredRequest: {
        Row: {
          createdAt: string
          deletedAt: string | null
          id: number
          requestBy: number
          status: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          deletedAt?: string | null
          id?: number
          requestBy: number
          status: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          deletedAt?: string | null
          id?: number
          requestBy?: number
          status?: number
          updatedAt?: string
        }
        Relationships: []
      }
      giveawayparticipants: {
        Row: {
          createdAt: string
          giveAwayId: number
          id: number
          updatedAt: string
          userId: number
        }
        Insert: {
          createdAt: string
          giveAwayId: number
          id?: number
          updatedAt: string
          userId: number
        }
        Update: {
          createdAt?: string
          giveAwayId?: number
          id?: number
          updatedAt?: string
          userId?: number
        }
        Relationships: []
      }
      giveawayRequest: {
        Row: {
          createdAt: string
          id: number
          requestBy: number
          status: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          id?: number
          requestBy: number
          status: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          id?: number
          requestBy?: number
          status?: number
          updatedAt?: string
        }
        Relationships: []
      }
      Giveaways: {
        Row: {
          createdAt: string
          description: string
          howToParticipate: string | null
          id: number
          image: string
          isDeclared: number
          sponsorId: Json
          termsAndConditions: string
          title: string
          updatedAt: string
          winnerAnnouncementDate: string
        }
        Insert: {
          createdAt: string
          description: string
          howToParticipate?: string | null
          id?: number
          image: string
          isDeclared: number
          sponsorId: Json
          termsAndConditions: string
          title: string
          updatedAt: string
          winnerAnnouncementDate: string
        }
        Update: {
          createdAt?: string
          description?: string
          howToParticipate?: string | null
          id?: number
          image?: string
          isDeclared?: number
          sponsorId?: Json
          termsAndConditions?: string
          title?: string
          updatedAt?: string
          winnerAnnouncementDate?: string
        }
        Relationships: []
      }
      groupChatUser: {
        Row: {
          active: number
          createdAt: string
          deletedAt: string | null
          group_admin: number
          groupId: string
          id: number
          mute: number
          updatedAt: string
          userId: string
        }
        Insert: {
          active: number
          createdAt: string
          deletedAt?: string | null
          group_admin: number
          groupId: string
          id?: number
          mute: number
          updatedAt: string
          userId: string
        }
        Update: {
          active?: number
          createdAt?: string
          deletedAt?: string | null
          group_admin?: number
          groupId?: string
          id?: number
          mute?: number
          updatedAt?: string
          userId?: string
        }
        Relationships: []
      }
      groupMessageRead: {
        Row: {
          createdAt: string | null
          deletedAt: string | null
          groupId: string
          id: number
          is_Read: number | null
          messageId: number
          updatedAt: string | null
          userId: number
        }
        Insert: {
          createdAt?: string | null
          deletedAt?: string | null
          groupId: string
          id?: number
          is_Read?: number | null
          messageId: number
          updatedAt?: string | null
          userId: number
        }
        Update: {
          createdAt?: string | null
          deletedAt?: string | null
          groupId?: string
          id?: number
          is_Read?: number | null
          messageId?: number
          updatedAt?: string | null
          userId?: number
        }
        Relationships: []
      }
      groupModel: {
        Row: {
          adminId: string
          createdAt: string | null
          deletedAt: string | null
          groupName: string
          id: number
          image: string
          updatedAt: string | null
        }
        Insert: {
          adminId: string
          createdAt?: string | null
          deletedAt?: string | null
          groupName: string
          id?: number
          image: string
          updatedAt?: string | null
        }
        Update: {
          adminId?: string
          createdAt?: string | null
          deletedAt?: string | null
          groupName?: string
          id?: number
          image?: string
          updatedAt?: string | null
        }
        Relationships: []
      }
      message: {
        Row: {
          addressId: string
          chatConstantId: string | null
          createdAt: string
          deletedAt: string | null
          deletedId: string | null
          groupId: string | null
          id: number
          message: string
          messageType: number | null
          readStatus: number | null
          receiverId: string
          receiverType: string
          senderId: string
          senderType: string
          thumbnail: string | null
          updatedAt: string
        }
        Insert: {
          addressId: string
          chatConstantId?: string | null
          createdAt: string
          deletedAt?: string | null
          deletedId?: string | null
          groupId?: string | null
          id?: number
          message: string
          messageType?: number | null
          readStatus?: number | null
          receiverId: string
          receiverType: string
          senderId: string
          senderType: string
          thumbnail?: string | null
          updatedAt: string
        }
        Update: {
          addressId?: string
          chatConstantId?: string | null
          createdAt?: string
          deletedAt?: string | null
          deletedId?: string | null
          groupId?: string | null
          id?: number
          message?: string
          messageType?: number | null
          readStatus?: number | null
          receiverId?: string
          receiverType?: string
          senderId?: string
          senderType?: string
          thumbnail?: string | null
          updatedAt?: string
        }
        Relationships: []
      }
      mute_users: {
        Row: {
          createdAt: string
          groupId: number
          id: number
          updatedAt: string
          user2Id: number
          userId: number
        }
        Insert: {
          createdAt: string
          groupId: number
          id?: number
          updatedAt: string
          user2Id: number
          userId: number
        }
        Update: {
          createdAt?: string
          groupId?: number
          id?: number
          updatedAt?: string
          user2Id?: number
          userId?: number
        }
        Relationships: []
      }
      notifications: {
        Row: {
          added_in_group: number | null
          createdAt: string
          deletedAt: string | null
          description: string
          featured_bussiness: number | null
          id: number
          image: string | null
          is_read: number | null
          new_giveaway: number | null
          notification_type: number | null
          receiver_id: number | null
          sponsor_accepted: number | null
          title: string
          trailerId: number
          updatedAt: string
          user_id: number
          winner_announced: number | null
        }
        Insert: {
          added_in_group?: number | null
          createdAt: string
          deletedAt?: string | null
          description: string
          featured_bussiness?: number | null
          id?: number
          image?: string | null
          is_read?: number | null
          new_giveaway?: number | null
          notification_type?: number | null
          receiver_id?: number | null
          sponsor_accepted?: number | null
          title: string
          trailerId: number
          updatedAt: string
          user_id: number
          winner_announced?: number | null
        }
        Update: {
          added_in_group?: number | null
          createdAt?: string
          deletedAt?: string | null
          description?: string
          featured_bussiness?: number | null
          id?: number
          image?: string | null
          is_read?: number | null
          new_giveaway?: number | null
          notification_type?: number | null
          receiver_id?: number | null
          sponsor_accepted?: number | null
          title?: string
          trailerId?: number
          updatedAt?: string
          user_id?: number
          winner_announced?: number | null
        }
        Relationships: []
      }
      product_images: {
        Row: {
          createdAt: string
          deletedAt: string | null
          id: number
          image: string | null
          order: number | null
          product_id: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          deletedAt?: string | null
          id?: number
          image?: string | null
          order?: number | null
          product_id: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          deletedAt?: string | null
          id?: number
          image?: string | null
          order?: number | null
          product_id?: number
          updatedAt?: string
        }
        Relationships: []
      }
      Products: {
        Row: {
          bussinessid: number
          createdAt: string
          deletedAt: string | null
          description: string | null
          id: number
          link: string
          linkDisplayed: string
          productName: string
          promo: string | null
          updatedAt: string
        }
        Insert: {
          bussinessid: number
          createdAt?: string
          deletedAt?: string | null
          description?: string | null
          id?: number
          link: string
          linkDisplayed: string
          productName: string
          promo?: string | null
          updatedAt?: string
        }
        Update: {
          bussinessid?: number
          createdAt?: string
          deletedAt?: string | null
          description?: string | null
          id?: number
          link?: string
          linkDisplayed?: string
          productName?: string
          promo?: string | null
          updatedAt?: string
        }
        Relationships: []
      }
      rating: {
        Row: {
          additional: number
          businessId: number
          comment: string | null
          createdAt: string
          durability: number
          easeOfUse: number
          factoryFeature: number
          finishQuality: number
          id: number
          maintenance: number
          overall_quality: number
          rating_average: number | null
          safety: number
          towing: number
          trailerId: number
          updatedAt: string
          valueOfMoney: number
        }
        Insert: {
          additional: number
          businessId: number
          comment?: string | null
          createdAt: string
          durability: number
          easeOfUse: number
          factoryFeature: number
          finishQuality: number
          id: number
          maintenance: number
          overall_quality: number
          rating_average?: number | null
          safety: number
          towing: number
          trailerId: number
          updatedAt: string
          valueOfMoney: number
        }
        Update: {
          additional?: number
          businessId?: number
          comment?: string | null
          createdAt?: string
          durability?: number
          easeOfUse?: number
          factoryFeature?: number
          finishQuality?: number
          id?: number
          maintenance?: number
          overall_quality?: number
          rating_average?: number | null
          safety?: number
          towing?: number
          trailerId?: number
          updatedAt?: string
          valueOfMoney?: number
        }
        Relationships: []
      }
      ratings: {
        Row: {
          additional: number
          businessId: number
          comment: string | null
          createdAt: string
          durability: number
          easeOfUse: number
          factoryFeature: number
          finishQuality: number
          id: number
          maintenance: number
          overall_quality: number
          rating_average: number | null
          safety: number
          towing: number
          trailerId: number
          updatedAt: string
          valueOfMoney: number
        }
        Insert: {
          additional: number
          businessId: number
          comment?: string | null
          createdAt: string
          durability: number
          easeOfUse: number
          factoryFeature: number
          finishQuality: number
          id?: number
          maintenance: number
          overall_quality: number
          rating_average?: number | null
          safety: number
          towing: number
          trailerId: number
          updatedAt: string
          valueOfMoney: number
        }
        Update: {
          additional?: number
          businessId?: number
          comment?: string | null
          createdAt?: string
          durability?: number
          easeOfUse?: number
          factoryFeature?: number
          finishQuality?: number
          id?: number
          maintenance?: number
          overall_quality?: number
          rating_average?: number | null
          safety?: number
          towing?: number
          trailerId?: number
          updatedAt?: string
          valueOfMoney?: number
        }
        Relationships: []
      }
      ReportedUsers: {
        Row: {
          createdAt: string
          id: number
          message: string | null
          reported_by: number
          reported_to: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          id?: number
          message?: string | null
          reported_by: number
          reported_to: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          id?: number
          message?: string | null
          reported_by?: number
          reported_to?: number
          updatedAt?: string
        }
        Relationships: []
      }
      service_images: {
        Row: {
          createdAt: string
          deletedAt: string | null
          id: number
          image: string
          order: number
          service_id: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          deletedAt?: string | null
          id?: number
          image: string
          order?: number
          service_id: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          deletedAt?: string | null
          id?: number
          image?: string
          order?: number
          service_id?: number
          updatedAt?: string
        }
        Relationships: []
      }
      services: {
        Row: {
          bussinessid: number
          createdAt: string
          deletedAt: string | null
          description: string
          id: number
          link: string
          linkDisplayed: string
          position: number
          promo: string | null
          serviceName: string
          updatedAt: string
        }
        Insert: {
          bussinessid: number
          createdAt: string
          deletedAt?: string | null
          description: string
          id?: number
          link: string
          linkDisplayed: string
          position: number
          promo?: string | null
          serviceName: string
          updatedAt: string
        }
        Update: {
          bussinessid?: number
          createdAt?: string
          deletedAt?: string | null
          description?: string
          id?: number
          link?: string
          linkDisplayed?: string
          position?: number
          promo?: string | null
          serviceName?: string
          updatedAt?: string
        }
        Relationships: []
      }
      set_trailer_feature: {
        Row: {
          createdAt: string
          deletedAt: string | null
          feature: number
          id: number
          trailer_id: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          deletedAt?: string | null
          feature: number
          id?: number
          trailer_id: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          deletedAt?: string | null
          feature?: number
          id?: number
          trailer_id?: number
          updatedAt?: string
        }
        Relationships: []
      }
      socketUser: {
        Row: {
          createdAt: string
          id: number
          isOnline: number | null
          socketId: string | null
          updatedAt: string
          userId: string | null
        }
        Insert: {
          createdAt: string
          id?: number
          isOnline?: number | null
          socketId?: string | null
          updatedAt: string
          userId?: string | null
        }
        Update: {
          createdAt?: string
          id?: number
          isOnline?: number | null
          socketId?: string | null
          updatedAt?: string
          userId?: string | null
        }
        Relationships: []
      }
      Subcategories: {
        Row: {
          categoryId: number
          createdAt: string
          id: number
          image: string | null
          name: string
          status: number
          updatedAt: string
        }
        Insert: {
          categoryId: number
          createdAt: string
          id?: number
          image?: string | null
          name: string
          status: number
          updatedAt: string
        }
        Update: {
          categoryId?: number
          createdAt?: string
          id?: number
          image?: string | null
          name?: string
          status?: number
          updatedAt?: string
        }
        Relationships: []
      }
      trailer_address: {
        Row: {
          contact_number: string
          country_code: string
          createdAt: string
          deletedAt: string
          description: string
          display_name: string
          email: string
          id: number
          image: string
          latitude: string
          location: string
          longitude: string
          store_number: string
          trailer_id: number
          updatedAt: string
          website: string
          zip_code: string
        }
        Insert: {
          contact_number: string
          country_code: string
          createdAt: string
          deletedAt: string
          description: string
          display_name: string
          email: string
          id?: number
          image: string
          latitude: string
          location: string
          longitude: string
          store_number: string
          trailer_id: number
          updatedAt: string
          website: string
          zip_code: string
        }
        Update: {
          contact_number?: string
          country_code?: string
          createdAt?: string
          deletedAt?: string
          description?: string
          display_name?: string
          email?: string
          id?: number
          image?: string
          latitude?: string
          location?: string
          longitude?: string
          store_number?: string
          trailer_id?: number
          updatedAt?: string
          website?: string
          zip_code?: string
        }
        Relationships: []
      }
      trailer_addresses: {
        Row: {
          additional_images: string[] | null
          business_id: number
          cityState: string
          contact_number: string
          country_code: string
          createdAt: string
          deletedAt: number
          description: string
          display_name: string
          email: string
          id: number
          image: string
          latitude: string
          location: string
          longitude: string
          preciseLocation: number
          store_number: string
          updatedAt: string
          website: string
          zip_code: string
        }
        Insert: {
          additional_images?: string[] | null
          business_id: number
          cityState: string
          contact_number: string
          country_code: string
          createdAt: string
          deletedAt: number
          description: string
          display_name: string
          email: string
          id?: number
          image: string
          latitude: string
          location: string
          longitude: string
          preciseLocation: number
          store_number: string
          updatedAt: string
          website: string
          zip_code: string
        }
        Update: {
          additional_images?: string[] | null
          business_id?: number
          cityState?: string
          contact_number?: string
          country_code?: string
          createdAt?: string
          deletedAt?: number
          description?: string
          display_name?: string
          email?: string
          id?: number
          image?: string
          latitude?: string
          location?: string
          longitude?: string
          preciseLocation?: number
          store_number?: string
          updatedAt?: string
          website?: string
          zip_code?: string
        }
        Relationships: []
      }
      trailer_documents: {
        Row: {
          createdAt: string
          deletedAt: number | null
          document_image: string
          document_title: string
          expiry_date: string
          id: number
          trailer_id: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          deletedAt?: number | null
          document_image: string
          document_title: string
          expiry_date: string
          id?: number
          trailer_id: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          deletedAt?: number | null
          document_image?: string
          document_title?: string
          expiry_date?: string
          id?: number
          trailer_id?: number
          updatedAt?: string
        }
        Relationships: []
      }
      trailer_logs: {
        Row: {
          createdAt: string
          date: string
          deletedAt: string | null
          description: string
          id: number
          next_date: string | null
          service_date: string
          service_description: string
          trailer_id: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          date: string
          deletedAt?: string | null
          description: string
          id?: number
          next_date?: string | null
          service_date: string
          service_description: string
          trailer_id: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          date?: string
          deletedAt?: string | null
          description?: string
          id?: number
          next_date?: string | null
          service_date?: string
          service_description?: string
          trailer_id?: number
          updatedAt?: string
        }
        Relationships: []
      }
      trailerFeature: {
        Row: {
          createdAt: string
          id: number
          position: number
          title: string
          updatedAt: string
        }
        Insert: {
          createdAt: string
          id?: number
          position: number
          title: string
          updatedAt: string
        }
        Update: {
          createdAt?: string
          id?: number
          position?: number
          title?: string
          updatedAt?: string
        }
        Relationships: []
      }
      trailerimages: {
        Row: {
          createdAt: string
          deletedAt: string | null
          id: number
          image: string
          trailerId: number
          updatedAt: string
        }
        Insert: {
          createdAt: string
          deletedAt?: string | null
          id?: number
          image: string
          trailerId: number
          updatedAt: string
        }
        Update: {
          createdAt?: string
          deletedAt?: string | null
          id?: number
          image?: string
          trailerId?: number
          updatedAt?: string
        }
        Relationships: []
      }
      Trailers: {
        Row: {
          brand: number
          bussinessid: number
          createdAt: string
          deletedAt: number | null
          displayName: string
          email: string | null
          id: number
          image: string
          length: number
          lengthUnit: string
          loadCapacity: number
          trailerName: string | null
          trailerType: number | null
          updatedAt: string
          width: number
          widthUnit: string
          winNumber: string
        }
        Insert: {
          brand: number
          bussinessid: number
          createdAt: string
          deletedAt?: number | null
          displayName: string
          email?: string | null
          id?: number
          image: string
          length: number
          lengthUnit: string
          loadCapacity: number
          trailerName?: string | null
          trailerType?: number | null
          updatedAt: string
          width: number
          widthUnit: string
          winNumber: string
        }
        Update: {
          brand?: number
          bussinessid?: number
          createdAt?: string
          deletedAt?: number | null
          displayName?: string
          email?: string | null
          id?: number
          image?: string
          length?: number
          lengthUnit?: string
          loadCapacity?: number
          trailerName?: string | null
          trailerType?: number | null
          updatedAt?: string
          width?: number
          widthUnit?: string
          winNumber?: string
        }
        Relationships: []
      }
      TrailerTypes: {
        Row: {
          added_by: number | null
          createdAt: string
          deletedAt: string | null
          id: number
          is_published: number
          title: string
          updatedAt: string
        }
        Insert: {
          added_by?: number | null
          createdAt: string
          deletedAt?: string | null
          id?: number
          is_published: number
          title: string
          updatedAt: string
        }
        Update: {
          added_by?: number | null
          createdAt?: string
          deletedAt?: string | null
          id?: number
          is_published?: number
          title?: string
          updatedAt?: string
        }
        Relationships: []
      }
      userCategories: {
        Row: {
          categoryId: string
          createdAt: string
          id: number
          updatedAt: string
          userId: string
        }
        Insert: {
          categoryId: string
          createdAt: string
          id?: number
          updatedAt: string
          userId: string
        }
        Update: {
          categoryId?: string
          createdAt?: string
          id?: number
          updatedAt?: string
          userId?: string
        }
        Relationships: []
      }
      Users: {
        Row: {
          color: string
          createdAt: string
          email: string | null
          id: number
          Image: string | null
          link: string
          name: string | null
          password: string | null
          role: string | null
          status: number | null
          updatedAt: string
        }
        Insert: {
          color: string
          createdAt: string
          email?: string | null
          id?: number
          Image?: string | null
          link: string
          name?: string | null
          password?: string | null
          role?: string | null
          status?: number | null
          updatedAt: string
        }
        Update: {
          color?: string
          createdAt?: string
          email?: string | null
          id?: number
          Image?: string | null
          link?: string
          name?: string | null
          password?: string | null
          role?: string | null
          status?: number | null
          updatedAt?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      delete_auth_user: { Args: never; Returns: Json }
      earth: { Args: never; Returns: number }
      get_businesses_in_radius: {
        Args: {
          category_ids?: number[]
          center_lat: number
          center_lng: number
          radius_km: number
          result_limit?: number
          search_query?: string
          type_filter?: number
        }
        Returns: {
          business_contact_number: string
          business_country_code: string
          category_id: number
          color: string
          description: string
          display_name: string
          distance_km: number
          email: string
          facebook: string
          id: number
          instagram: string
          is_featured: number
          latitude: number
          location: string
          longitude: number
          profile_image: string
          regularCityState: string
          regularPreciseLocation: string
          status: number
          subscriptionStatus: string
          subscriptionType: number
          tiktok: string
          twitter: string
          website: string
          youtube: string
        }[]
      }
      get_featured_businesses_by_viewport: {
        Args: { center_lat: number; center_lng: number; result_limit?: number }
        Returns: {
          category_id: number
          color: string
          country_code: string
          createdat: string
          deletedat: string
          description: string
          display_name: string
          distance_km: number
          email: string
          facebook: string
          id: number
          instagram: string
          is_featured: number
          latitude: number
          location: string
          longitude: number
          mobile_number: string
          profile_image: string
          regularcitystate: string
          regularpreciselocation: string
          status: number
          subscriptiontype: number
          tiktok: string
          twitter: string
          updatedat: string
          website: string
        }[]
      }
      soft_delete_business: { Args: never; Returns: Json }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
