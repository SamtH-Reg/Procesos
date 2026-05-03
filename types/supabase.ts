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
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      app_kv: {
        Row: {
          key: string
          updated_at: string | null
          value: Json
        }
        Insert: {
          key: string
          updated_at?: string | null
          value?: Json
        }
        Update: {
          key?: string
          updated_at?: string | null
          value?: Json
        }
        Relationships: []
      }
      armado_linea: {
        Row: {
          area: string
          fecha: string
          linea: string
          planillero: Json | null
          producto: string | null
          trabajadores: Json | null
          turno: string
          updated_at: string | null
        }
        Insert: {
          area: string
          fecha?: string
          linea: string
          planillero?: Json | null
          producto?: string | null
          trabajadores?: Json | null
          turno: string
          updated_at?: string | null
        }
        Update: {
          area?: string
          fecha?: string
          linea?: string
          planillero?: Json | null
          producto?: string | null
          trabajadores?: Json | null
          turno?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      armado_lineas: {
        Row: {
          area: string
          especie: string | null
          fecha: string
          linea: string
          planillero: Json | null
          trabajadores: Json | null
          turno: string
          updated_at: string | null
        }
        Insert: {
          area?: string
          especie?: string | null
          fecha?: string
          linea: string
          planillero?: Json | null
          trabajadores?: Json | null
          turno: string
          updated_at?: string | null
        }
        Update: {
          area?: string
          especie?: string | null
          fecha?: string
          linea?: string
          planillero?: Json | null
          trabajadores?: Json | null
          turno?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      equipos: {
        Row: {
          activo: boolean | null
          capacidad: number | null
          codigo: string
          nombre: string | null
          tipo: string | null
          updated_at: string | null
        }
        Insert: {
          activo?: boolean | null
          capacidad?: number | null
          codigo: string
          nombre?: string | null
          tipo?: string | null
          updated_at?: string | null
        }
        Update: {
          activo?: boolean | null
          capacidad?: number | null
          codigo?: string
          nombre?: string | null
          tipo?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      moldes: {
        Row: {
          calibre: string | null
          cant: number | null
          codigo: string | null
          created_at: string | null
          destino: string | null
          especie: string | null
          fecha: string | null
          ficha: string | null
          guia: string | null
          hora: string | null
          id: number
          kg: number | null
          linea: string | null
          nombre: string | null
          pendiente: number | null
          preset_id: number | null
          producto: string | null
          turno: string | null
        }
        Insert: {
          calibre?: string | null
          cant?: number | null
          codigo?: string | null
          created_at?: string | null
          destino?: string | null
          especie?: string | null
          fecha?: string | null
          ficha?: string | null
          guia?: string | null
          hora?: string | null
          id: number
          kg?: number | null
          linea?: string | null
          nombre?: string | null
          pendiente?: number | null
          preset_id?: number | null
          producto?: string | null
          turno?: string | null
        }
        Update: {
          calibre?: string | null
          cant?: number | null
          codigo?: string | null
          created_at?: string | null
          destino?: string | null
          especie?: string | null
          fecha?: string | null
          ficha?: string | null
          guia?: string | null
          hora?: string | null
          id?: number
          kg?: number | null
          linea?: string | null
          nombre?: string | null
          pendiente?: number | null
          preset_id?: number | null
          producto?: string | null
          turno?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "moldes_preset_id_fkey"
            columns: ["preset_id"]
            isOneToOne: false
            referencedRelation: "presets"
            referencedColumns: ["id"]
          },
        ]
      }
      pesajes: {
        Row: {
          codigo: string | null
          created_at: string | null
          especie: string | null
          fecha: string | null
          ficha: string | null
          guia: string | null
          hora: string | null
          id: number
          kg: number | null
          linea: string | null
          nombre: string | null
          tipo: string | null
          trab_id: number | null
          turno: string | null
        }
        Insert: {
          codigo?: string | null
          created_at?: string | null
          especie?: string | null
          fecha?: string | null
          ficha?: string | null
          guia?: string | null
          hora?: string | null
          id: number
          kg?: number | null
          linea?: string | null
          nombre?: string | null
          tipo?: string | null
          trab_id?: number | null
          turno?: string | null
        }
        Update: {
          codigo?: string | null
          created_at?: string | null
          especie?: string | null
          fecha?: string | null
          ficha?: string | null
          guia?: string | null
          hora?: string | null
          id?: number
          kg?: number | null
          linea?: string | null
          nombre?: string | null
          tipo?: string | null
          trab_id?: number | null
          turno?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pesajes_trab_id_fkey"
            columns: ["trab_id"]
            isOneToOne: false
            referencedRelation: "trabajadores"
            referencedColumns: ["id"]
          },
        ]
      }
      presets: {
        Row: {
          activo: boolean | null
          calibre: string | null
          created_at: string | null
          destino: string | null
          especie: string | null
          formato: string | null
          horas_placa: number | null
          horas_tunel: number | null
          id: number
          kg_ref: number | null
          nombre: string
          temp_obj: number | null
          tipo: string | null
          updated_at: string | null
        }
        Insert: {
          activo?: boolean | null
          calibre?: string | null
          created_at?: string | null
          destino?: string | null
          especie?: string | null
          formato?: string | null
          horas_placa?: number | null
          horas_tunel?: number | null
          id: number
          kg_ref?: number | null
          nombre: string
          temp_obj?: number | null
          tipo?: string | null
          updated_at?: string | null
        }
        Update: {
          activo?: boolean | null
          calibre?: string | null
          created_at?: string | null
          destino?: string | null
          especie?: string | null
          formato?: string | null
          horas_placa?: number | null
          horas_tunel?: number | null
          id?: number
          kg_ref?: number | null
          nombre?: string
          temp_obj?: number | null
          tipo?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      roles: {
        Row: {
          id: number
          nombre: string
          permisos: Json
          updated_at: string | null
        }
        Insert: {
          id: number
          nombre: string
          permisos?: Json
          updated_at?: string | null
        }
        Update: {
          id?: number
          nombre?: string
          permisos?: Json
          updated_at?: string | null
        }
        Relationships: []
      }
      trabajadores: {
        Row: {
          activo: boolean | null
          area: string | null
          codigo: string | null
          created_at: string | null
          ficha: string | null
          id: number
          linea: string | null
          nombre: string
          rol: string | null
          turno: string | null
          updated_at: string | null
        }
        Insert: {
          activo?: boolean | null
          area?: string | null
          codigo?: string | null
          created_at?: string | null
          ficha?: string | null
          id: number
          linea?: string | null
          nombre: string
          rol?: string | null
          turno?: string | null
          updated_at?: string | null
        }
        Update: {
          activo?: boolean | null
          area?: string | null
          codigo?: string | null
          created_at?: string | null
          ficha?: string | null
          id?: number
          linea?: string | null
          nombre?: string
          rol?: string | null
          turno?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      turnos: {
        Row: {
          activo: boolean | null
          codigo: string
          fin: string | null
          inicio: string | null
          nombre: string | null
          updated_at: string | null
        }
        Insert: {
          activo?: boolean | null
          codigo: string
          fin?: string | null
          inicio?: string | null
          nombre?: string | null
          updated_at?: string | null
        }
        Update: {
          activo?: boolean | null
          codigo?: string
          fin?: string | null
          inicio?: string | null
          nombre?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          activo: boolean | null
          area: string | null
          created_at: string | null
          email: string | null
          id: string
          nombre: string | null
          rol: string
        }
        Insert: {
          activo?: boolean | null
          area?: string | null
          created_at?: string | null
          email?: string | null
          id: string
          nombre?: string | null
          rol?: string
        }
        Update: {
          activo?: boolean | null
          area?: string | null
          created_at?: string | null
          email?: string | null
          id?: string
          nombre?: string | null
          rol?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_write: { Args: never; Returns: boolean }
      crear_usuario_friosur: {
        Args: {
          p_email: string
          p_nombre: string
          p_password: string
          p_rol: string
        }
        Returns: string
      }
      current_rol: { Args: never; Returns: string }
      is_admin: { Args: never; Returns: boolean }
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
