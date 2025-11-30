# Sistema Universal de Reservas

Sistema de gestión de reservas multipropósito, diseñado para ser modular, adaptable y completamente agnóstico respecto a cualquier industria o rubro específico.

## Características Principales

### 1. Gestión de Reservas
- **Crear reservas**: Nombre del cliente, fecha, hora, servicio, duración y observaciones
- **Validar disponibilidad**: Prevención automática de conflictos de horarios
- **Editar reservas**: Modificación de reservas existentes
- **Confirmar/Cancelar**: Control del estado de cada reserva

### 2. Gestión de Profesionales/Recursos
- Soporte para múltiples profesionales o recursos en paralelo
- Cada profesional puede ofrecer diferentes servicios
- Agenda individual por profesional

### 3. Gestión de Servicios
- Catálogo configurable de servicios
- Cada servicio puede tener diferente duración
- Asignación de profesionales a servicios específicos

### 4. Sistema de Usuarios
- Registro y autenticación de usuarios
- Perfil de cliente con datos de contacto
- Vista diferenciada para clientes y profesionales

## Estructura del Sistema

```
src/
├── controllers/          # Lógica de negocio
│   ├── reservas.controller.js  # Gestión de reservas
│   ├── auth.controller.js      # Autenticación
│   └── ...
├── routes/              # Definición de rutas API
├── views/               # Plantillas Handlebars
│   ├── layouts/         # Plantillas base
│   ├── partials/        # Componentes reutilizables
│   └── reservas/        # Vistas de reservas
├── lib/                 # Utilidades y helpers
└── public/              # Archivos estáticos
```

## Modelo de Datos

### Entidades Principales

- **users**: Usuarios del sistema
- **personas**: Datos personales extendidos
- **servicios**: Catálogo de servicios disponibles
- **empleados**: Profesionales que ofrecen servicios (relacionados con personas y servicios)
- **agenda**: Disponibilidad de horarios por profesional
- **bloque**: Bloques de tiempo (hora inicio/fin)
- **reservas**: Reservas realizadas

### Estados de Reserva
- `0`: Pendiente
- `1`: Confirmada
- `2`: Atendida/Completada

## Instalación

```bash
# Clonar el repositorio
git clone <url-del-repositorio>

# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env
# Editar .env con los datos de tu base de datos

# Iniciar en modo desarrollo
npm run dev

# Iniciar en producción
npm start
```

## Variables de Entorno

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=railway
DB_PORT=3306
PORT=4000
```

## API de Reservas

### Rutas Disponibles

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/reservas` | Listar reservas del usuario |
| POST | `/reservas` | Buscar disponibilidad |
| POST | `/reservas/agregar` | Agregar datos de cliente |
| GET | `/reservas/tomar/:id` | Tomar una reserva disponible |
| GET | `/reservas/confirmar/:id` | Confirmar una reserva |
| GET | `/reservas/pendiente/:id` | Marcar como pendiente |
| GET | `/reservas/eliminar/:id` | Cancelar una reserva |

## Flujo de Reserva (Usuario Final)

1. **Registro/Inicio de sesión**: El usuario debe estar autenticado
2. **Completar perfil**: Datos de contacto (nombre, teléfono, correo, observaciones)
3. **Seleccionar servicio**: Elegir el tipo de servicio deseado
4. **Elegir fecha**: Seleccionar la fecha preferida
5. **Ver disponibilidad**: El sistema muestra horarios disponibles
6. **Confirmar reserva**: Seleccionar el horario y profesional
7. **Seguimiento**: Ver estado de la reserva en el panel

## Flujo de Reserva (Profesional)

1. **Vista de reservas**: Ver todas las reservas asignadas
2. **Pendientes**: Lista de reservas por confirmar
3. **Confirmar**: Aprobar reservas pendientes
4. **Atender**: Marcar reservas como completadas
5. **Cancelar**: Anular reservas si es necesario

## Mejoras Estructurales Recomendadas

### Para escalabilidad:
- Implementar caché con Redis para consultas frecuentes
- Añadir paginación en listados grandes
- Implementar búsqueda avanzada con filtros

### Para modernización:
- Migrar a una API REST completa
- Implementar validación con JSON Schema
- Añadir documentación OpenAPI/Swagger
- Implementar WebSockets para actualizaciones en tiempo real

### Para seguridad:
- Implementar rate limiting
- Añadir CSRF protection
- Implementar auditoría de acciones
- Encriptar datos sensibles en base de datos

### Para integración:
- API para integración con calendarios externos (Google Calendar, Outlook)
- Webhooks para notificaciones
- Exportación de datos en múltiples formatos (CSV, JSON, iCal)

## Tecnologías Utilizadas

- **Backend**: Node.js con Express
- **Vista**: Handlebars (HBS)
- **Base de datos**: MySQL
- **Autenticación**: Passport.js
- **Sesiones**: express-session con MySQL store

## Licencia

ISC

## Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue primero para discutir los cambios propuestos.
