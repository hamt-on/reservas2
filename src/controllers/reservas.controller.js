import { pool } from "../database.js";

/**
 * Estados de reserva:
 * 0 = Pendiente
 * 1 = Confirmada
 * 2 = Completada/Atendida
 * 3 = Cancelada
 */

/**
 * Agregar datos de perfil del cliente
 * Crea registro en personas y clientes (pacientes para compatibilidad)
 */
export const agregarPersona = async (req, res, next) => {
    const { rut, nombres, apepat, apemat, correo, telefono, prevision } = req.body;
    const nuevo = {
      rut,
      nombres,
      apepat,
      apemat,
      telefono,
      correo,
      idusuario : req.user.id
    }; 
    await pool.query("INSERT INTO personas set ?", [nuevo])
    const [persona] = await pool.query('SELECT idpersonas FROM personas WHERE idusuario = ?', [req.user.id])
    const cliente = {
        idpersonas : persona[0].idpersonas,
        prevision
    };
    await pool.query("INSERT INTO pacientes set ?", [cliente])
    res.redirect("/reservas")
};

/**
 * Listar reservas del usuario actual
 * Muestra reservas propias y (si es profesional) las reservas asignadas
 */
export const listarReservas = async (req, res, next) => {
    const [persona] = await pool.query('SELECT * FROM personas WHERE idusuario = ?', [req.user.id])
    const [clientes] = await pool.query('SELECT a.*, b.* FROM personas a JOIN pacientes b ON a.idpersonas = b.idpersonas WHERE a.idusuario = ?', [req.user.id])
    const [reservas] = await pool.query('SELECT a.idreservas, DATE_FORMAT(b.fecha,"%d/%m/%Y") AS fecha, DATE_FORMAT(c.comienza,"%H:%i") AS hora, CONCAT(e.nombres, " ",e.apepat, " ", e.apemat) AS nombre, f.nombre AS servicio FROM reservas a JOIN agenda b ON a.idagenda = b.idagenda JOIN bloque c ON b.idbloque = c.idbloque JOIN empleados d ON d.idempleados = b.idempleados JOIN personas e ON e.idpersonas = d.idpersonas JOIN servicios f ON f.idservicios = d.idservicios WHERE a.idusuario = ? ORDER BY a.idreservas ASC', [req.user.id])
    const [rows] = await pool.query("SELECT * FROM servicios")
    const [profesional] = await pool.query('SELECT a.idreservas, DATE_FORMAT(b.fecha,"%d/%m/%Y") AS fecha, DATE_FORMAT(c.comienza,"%H:%i") AS hora, CONCAT(g.nombres, " ",g.apepat, " ", g.apemat) AS nombre FROM reservas a JOIN agenda b ON a.idagenda = b.idagenda JOIN bloque c ON b.idbloque = c.idbloque JOIN empleados d ON d.idempleados = b.idempleados JOIN personas e ON e.idpersonas = d.idpersonas JOIN servicios f ON f.idservicios = d.idservicios JOIN personas g ON g.idusuario =  a.idusuario WHERE e.idusuario = ? ORDER BY a.idreservas ASC', [req.user.id])
    const [confirmados] = await pool.query('SELECT a.idreservas, DATE_FORMAT(b.fecha,"%d/%m/%Y") AS fecha, DATE_FORMAT(c.comienza,"%H:%i") AS hora, CONCAT(g.nombres, " ",g.apepat, " ", g.apemat) AS nombre FROM reservas a JOIN agenda b ON a.idagenda = b.idagenda JOIN bloque c ON b.idbloque = c.idbloque JOIN empleados d ON d.idempleados = b.idempleados JOIN personas e ON e.idpersonas = d.idpersonas JOIN servicios f ON f.idservicios = d.idservicios JOIN personas g ON g.idusuario =  a.idusuario WHERE e.idusuario = ? AND a.estado = 1 ORDER BY a.idreservas ASC', [req.user.id])
    const [pendientes] = await pool.query('SELECT a.idreservas, DATE_FORMAT(b.fecha,"%d/%m/%Y") AS fecha, DATE_FORMAT(c.comienza,"%H:%i") AS hora, CONCAT(g.nombres, " ",g.apepat, " ", g.apemat) AS nombre FROM reservas a JOIN agenda b ON a.idagenda = b.idagenda JOIN bloque c ON b.idbloque = c.idbloque JOIN empleados d ON d.idempleados = b.idempleados JOIN personas e ON e.idpersonas = d.idpersonas JOIN servicios f ON f.idservicios = d.idservicios JOIN personas g ON g.idusuario =  a.idusuario WHERE e.idusuario = ? AND a.estado = 0 ORDER BY a.idreservas ASC', [req.user.id])
    res.render("reservas/reservas",{ servicios : rows , reservas : reservas , pacientes : clientes, persona: persona, empleado: profesional, confirmados: confirmados, pendientes:pendientes})
};

/**
 * Buscar disponibilidad de reservas
 * Filtra por servicio y fecha, retorna horarios disponibles
 */
export const buscarReserva = async (req, res, next) => {
    let fechaForm = req.body.fecha
    let serviciosForm = req.body.servicios
    let arr1 = fechaForm.split('/')
    let fecha = arr1[2]+'-'+arr1[1]+'-'+arr1[0]
    const [persona] = await pool.query('SELECT * FROM personas WHERE idusuario = ?', [req.user.id])
    const [clientes] = await pool.query('SELECT a.*, b.* FROM personas a JOIN pacientes b ON a.idpersonas = b.idpersonas WHERE a.idusuario = ?', [req.user.id])    
    const [reservas] = await pool.query('SELECT a.idreservas, DATE_FORMAT(b.fecha,"%d/%m/%Y") AS fecha, DATE_FORMAT(c.comienza,"%H:%i") AS hora, CONCAT(e.nombres, " ",e.apepat, " ", e.apemat) AS nombre, f.nombre AS servicio FROM reservas a JOIN agenda b ON a.idagenda = b.idagenda JOIN bloque c ON b.idbloque = c.idbloque JOIN empleados d ON d.idempleados = b.idempleados JOIN personas e ON e.idpersonas = d.idpersonas JOIN servicios f ON f.idservicios = d.idservicios WHERE a.idusuario = ? ORDER BY a.idreservas ASC', [req.user.id]) 
    const [horas] = await pool.query('SELECT DATE_FORMAT(a.fecha,"%d/%m/%Y") AS fecha, CONCAT(d.nombres, " ",d.apepat, " ", d.apemat) AS nombre , DATE_FORMAT(b.comienza,"%H:%i") AS hora, a.idagenda FROM agenda as a INNER JOIN bloque AS b ON a.idbloque = b.idbloque INNER JOIN empleados AS c ON a.idempleados = c.idempleados INNER JOIN personas AS d ON c.idpersonas = d.idpersonas LEFT JOIN reservas e ON e.idagenda = a.idagenda WHERE DATE(a.fecha) >= ? AND c.idservicios = ? AND e.idagenda IS NULL ORDER by a.fecha ASC LIMIT 5', [fecha, serviciosForm]) 
    const [rows] = await pool.query("SELECT * FROM servicios")
    const [profesional] = []
    res.render("reservas/reservas",{ servicios : rows , reservas : reservas , pacientes : clientes, persona: persona, horas:horas, empleado: profesional})
};

/**
 * Tomar/Crear una nueva reserva
 * Valida disponibilidad antes de crear la reserva
 */
export const tomarReserva = async (req, res, next) => {
    const { id } = req.params
    
    // Verificar que el slot no esté ya reservado (validación de conflictos)
    const [existente] = await pool.query('SELECT idreservas FROM reservas WHERE idagenda = ?', [id])
    if (existente.length > 0) {
        req.flash("error", "Este horario ya no está disponible")
        return res.redirect("/reservas")
    }
    
    const nuevo = { 
      idusuario : req.user.id,
      idagenda : id,
      estado : 0 
    }
    await pool.query("INSERT INTO reservas set ?", [nuevo])
    req.flash("success", "Reserva creada exitosamente")
    res.redirect("/reservas")
};

/**
 * Confirmar una reserva pendiente
 * Cambia estado de 0 (pendiente) a 1 (confirmada)
 */
export const confirmarReserva = async (req, res, next) => {
    const { id } = req.params
    const nuevo = { 
      estado : 1 
    }
    await pool.query("UPDATE reservas SET ? WHERE idreservas = ?", [nuevo,id] )
    req.flash("success", "Reserva confirmada")
    res.redirect("/reservas")
};

/**
 * Marcar reserva como pendiente
 * Cambia estado a 0 (pendiente)
 */
export const pendienteReserva = async (req, res, next) => {
    const { id } = req.params
    const nuevo = { 
      estado : 0 
    }
    await pool.query("UPDATE reservas SET ? WHERE idreservas = ?", [nuevo,id] )
    res.redirect("/reservas")
};

/**
 * Marcar reserva como atendida/completada
 * Cambia estado a 2 (completada)
 */
export const atenderReserva = async (req, res, next) => {
    const { id } = req.params
    const nuevo = { 
      estado : 2 
    }
    await pool.query("UPDATE reservas SET ? WHERE idreservas = ?", [nuevo,id] )
    res.redirect("./demo")
};

/**
 * Cancelar/Eliminar una reserva
 * Elimina el registro de la reserva
 */
export const eliminarReserva = async (req, res, next) => {
    const { id } = req.params
    await pool.query("DELETE FROM reservas WHERE idreservas = ?", id)
    req.flash("success", "Reserva cancelada")
    res.redirect("/reservas")
};  