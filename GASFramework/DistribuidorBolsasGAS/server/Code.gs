// Code.gs
// Não altere o valor das variáveis abaixo; edite em placeholders.json.
//Placeholders_INI:
const SPREADSHEET_ID = "1YM2YQZuk6qgyQf_XYbHkvp5D75KueqMIi9lvkL56oDs";
//Placeholders_FIM

const DEFAULT_DEPARTMENTS = ['DBPVA', 'DCNME', 'DDR', 'DTAiSeR', 'DRNPA'];
const DEFAULT_REPRESENTANTES = [
  { dept: 'DBPVA', nome: 'Representante DBPVA', emails: ['email@exemplo.com'] },
  { dept: 'DCNME', nome: 'Representante DCNME', emails: ['email@exemplo.com'] },
  { dept: 'DDR', nome: 'Representante DDR', emails: ['email@exemplo.com'] },
  { dept: 'DTAiSeR', nome: 'Representante DTAiSeR', emails: ['email@exemplo.com'] },
  { dept: 'DRNPA', nome: 'Representante DRNPA', emails: ['email@exemplo.com'] }
];

const SHEET_REP = 'Representantes';
const SHEET_DISC = 'Disciplinas';

/**
 * Função principal que serve a aplicação web.
 */
function doGet() {
  const template = HtmlService.createTemplateFromFile('index.html');
  return template
    .evaluate()
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

function getAppData() {
  const ss = getSpreadsheet_();
  ensureSheets_(ss);

  const reps = getRepresentantes_(ss);
  const departments = reps.map(r => r.dept);
  const userEmail = (Session.getActiveUser().getEmail() || '').toLowerCase();
  const userDept = getUserDept_(userEmail, reps);

  const disciplinesByDept = getDisciplinesByDept_(ss, departments);

  return {
    userEmail: userEmail,
    userDept: userDept,
    departments: departments,
    representatives: reps,
    disciplinesByDept: disciplinesByDept
  };
}

function saveAppData(payload) {
  const ss = getSpreadsheet_();
  ensureSheets_(ss);

  const reps = getRepresentantes_(ss);
  const userEmail = (Session.getActiveUser().getEmail() || '').toLowerCase();
  const userDept = getUserDept_(userEmail, reps);
  if (!userDept) {
    throw new Error('Seu e-mail não está cadastrado como representante.');
  }

  const disciplines = payload && payload.disciplines ? payload.disciplines : [];
  validateDisciplines_(disciplines);
  saveDisciplinesForDept_(ss, userDept, disciplines, userEmail);

  return { ok: true };
}

function generateClassification(payload) {
  const ss = getSpreadsheet_();
  ensureSheets_(ss);

  const reps = getRepresentantes_(ss);
  const departments = reps.map(r => r.dept);
  const settings = payload && payload.settings ? payload.settings : {};
  const disciplinesByDept = getDisciplinesByDept_(ss, departments);

  const computation = computeDistributions_(departments, disciplinesByDept, settings);
  return computation;
}

function generatePdf(classification) {
  if (!classification) {
    throw new Error('Classificação não informada.');
  }

  const html = buildPdfHtml_(classification);
  const blob = HtmlService.createHtmlOutput(html).getBlob().getAs('application/pdf');
  const fileName = 'Distribuicao_Bolsas_' + new Date().toISOString().replace(/[:.]/g, '-') + '.pdf';
  const file = DriveApp.createFile(blob).setName(fileName);
  return { url: file.getUrl(), name: fileName, id: file.getId() };
}

// ----------------- Helpers -----------------

function getSpreadsheet_() {
  if (!SPREADSHEET_ID || SPREADSHEET_ID === 'SEU_ID_AQUI') {
    throw new Error('Configure o SPREADSHEET_ID em placeholders.json.');
  }
  return SpreadsheetApp.openById(SPREADSHEET_ID);
}

function ensureSheets_(ss) {
  let sheet = ss.getSheetByName(SHEET_REP);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_REP);
    sheet.getRange(1, 1, 1, 3).setValues([['Departamento', 'Nome', 'Emails']]);
    const rows = DEFAULT_REPRESENTANTES.map(r => [r.dept, r.nome, r.emails.join(',')]);
    sheet.getRange(2, 1, rows.length, 3).setValues(rows);
  }

  sheet = ss.getSheetByName(SHEET_DISC);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_DISC);
    sheet.getRange(1, 1, 1, 7).setValues([['Departamento', 'Codigo', 'Disciplina', 'Professor', 'CT', 'CP', 'AtualizadoPor']]);
  }

}

function getRepresentantes_(ss) {
  const sheet = ss.getSheetByName(SHEET_REP);
  const values = sheet.getDataRange().getValues();
  const reps = [];
  for (let i = 1; i < values.length; i++) {
    const [dept, nome, emailsRaw] = values[i];
    if (!dept) continue;
    const emails = String(emailsRaw || '')
      .split(',')
      .map(e => e.trim().toLowerCase())
      .filter(Boolean);
    reps.push({ dept: String(dept).trim(), nome: String(nome || '').trim(), emails: emails });
  }
  if (!reps.length) {
    return DEFAULT_REPRESENTANTES;
  }
  return reps;
}

function getUserDept_(email, reps) {
  if (!email) return null;
  for (let i = 0; i < reps.length; i++) {
    if (reps[i].emails.indexOf(email) >= 0) {
      return reps[i].dept;
    }
  }
  return null;
}

function getDisciplinesByDept_(ss, departments) {
  const sheet = ss.getSheetByName(SHEET_DISC);
  const values = sheet.getDataRange().getValues();
  const data = {};
  departments.forEach(d => { data[d] = []; });
  for (let i = 1; i < values.length; i++) {
    const [dept, codigo, disciplina, professor, ct, cp] = values[i];
    if (!dept || !data[dept]) continue;
    data[dept].push({
      codigo: String(codigo || '').trim(),
      disciplina: String(disciplina || '').trim(),
      professor: String(professor || '').trim(),
      ct: Number(ct || 0),
      cp: Number(cp || 0)
    });
  }
  return data;
}

function saveDisciplinesForDept_(ss, dept, disciplines, userEmail) {
  const sheet = ss.getSheetByName(SHEET_DISC);
  const values = sheet.getDataRange().getValues();
  const header = values.length ? values[0] : ['Departamento', 'Codigo', 'Disciplina', 'Professor', 'CT', 'CP', 'AtualizadoPor'];
  const filtered = [header];
  for (let i = 1; i < values.length; i++) {
    if (String(values[i][0] || '').trim() !== dept) {
      filtered.push(values[i]);
    }
  }
  const now = new Date().toISOString();
  const rows = disciplines.map(d => [
    dept,
    d.codigo,
    d.disciplina,
    d.professor,
    d.ct,
    d.cp,
    userEmail + ' @ ' + now
  ]);

  const newValues = filtered.concat(rows);
  sheet.clearContents();
  sheet.getRange(1, 1, newValues.length, header.length).setValues(newValues);
}

function validateDisciplines_(disciplines) {
  disciplines.forEach((d, idx) => {
    const codeOk = /^\d{6}$/.test(String(d.codigo || ''));
    if (!codeOk) throw new Error('Código inválido na disciplina #' + (idx + 1));
    const ct = Number(d.ct);
    const cp = Number(d.cp);
    if (isNaN(ct) || isNaN(cp)) throw new Error('CT/CP inválidos na disciplina #' + (idx + 1));
    if (ct < 0 || ct > 6 || cp < 0 || cp > 6) {
      throw new Error('CT/CP devem estar entre 0 e 6 na disciplina #' + (idx + 1));
    }
    const sum = ct + cp;
    if (sum < 1 || sum > 6) {
      throw new Error('CT + CP deve estar entre 1 e 6 na disciplina #' + (idx + 1));
    }
  });
}

function computeDistributions_(departments, disciplinesByDept, settings) {
  const requests = {};
  const disciplinesWithWeight = {};
  departments.forEach(dept => {
    const list = disciplinesByDept[dept] || [];
    let sum = 0;
    disciplinesWithWeight[dept] = list.map(d => {
      const ct = Number(d.ct || 0);
      const cp = Number(d.cp || 0);
      const weight = ct + cp > 0 ? 1 + (cp / (ct + cp)) : 0;
      sum += weight;
      return {
        codigo: d.codigo,
        disciplina: d.disciplina,
        professor: d.professor,
        ct: ct,
        cp: cp,
        peso: weight
      };
    });
    requests[dept] = sum;
  });

  const semester = settings.semester === 'even' ? 'even' : 'odd';
  const totalBolsas = clampInt_(settings.totalBolsas, 1, 30);
  const nMelhores = clampInt_(settings.nMelhores, 1, 10);

  let active = departments.filter(dept => requests[dept] > 0);
  if (semester === 'even') {
    active = active.filter(dept => dept !== 'DRNPA');
  }

  const minAlloc = {};
  active.forEach(dept => { minAlloc[dept] = 1; });
  if (semester === 'odd' && active.indexOf('DRNPA') >= 0) {
    minAlloc['DRNPA'] = 2;
  }

  const minSum = active.reduce((acc, dept) => acc + (minAlloc[dept] || 0), 0);
  if (totalBolsas < minSum) {
    return {
      ok: false,
      error: 'Bolsas disponíveis insuficientes para atender os mínimos (' + minSum + ').',
      settings: settings,
      departments: departments,
      requests: requests,
      disciplines: disciplinesWithWeight,
      results: []
    };
  }

  if (!active.length) {
    return {
      ok: false,
      error: 'Nenhum departamento ativo com solicitações.',
      settings: settings,
      departments: departments,
      requests: requests,
      disciplines: disciplinesWithWeight,
      results: []
    };
  }

  const residual = totalBolsas - minSum;
  const activeRequests = active.map(dept => requests[dept]);

  const allResults = [];
  compositions_(residual, active.length, function(parts) {
    const alloc = parts.map((v, idx) => v + (minAlloc[active[idx]] || 0));
    const ratios = alloc.map((v, idx) => v / activeRequests[idx]);
    const sd = ratios.length >= 2 ? stdev_(ratios) : 0;
    allResults.push({ alloc: alloc, sd: sd });
  });

  allResults.sort(function(a, b) { return a.sd - b.sd; });
  const limited = allResults.slice(0, Math.min(nMelhores, allResults.length));

  const results = limited.map(r => {
    const allocByDept = {};
    departments.forEach(dept => { allocByDept[dept] = 0; });
    active.forEach((dept, idx) => { allocByDept[dept] = r.alloc[idx]; });
    const ratiosByDept = {};
    departments.forEach(dept => {
      ratiosByDept[dept] = requests[dept] > 0 ? (allocByDept[dept] / requests[dept]) : null;
    });
    return {
      allocByDept: allocByDept,
      ratiosByDept: ratiosByDept,
      sd: r.sd
    };
  });

  return {
    ok: true,
    settings: settings,
    departments: departments,
    activeDepartments: active,
    requests: requests,
    disciplines: disciplinesWithWeight,
    results: results
  };
}

function compositions_(total, parts, callback) {
  if (parts === 1) {
    callback([total]);
    return;
  }
  for (let i = 0; i <= total; i++) {
    compositions_(total - i, parts - 1, function(rest) {
      callback([i].concat(rest));
    });
  }
}

function stdev_(arr) {
  const n = arr.length;
  if (n < 2) return 0;
  let mean = 0;
  arr.forEach(v => { mean += v; });
  mean = mean / n;
  let sumsq = 0;
  arr.forEach(v => { sumsq += Math.pow(v - mean, 2); });
  return Math.sqrt(sumsq / (n - 1));
}

function clampInt_(value, min, max) {
  const v = Math.round(Number(value || 0));
  if (isNaN(v)) return min;
  return Math.min(max, Math.max(min, v));
}

function buildPdfHtml_(classification) {
  const dpts = classification.departments || [];
  const disciplines = classification.disciplines || {};
  const results = classification.results || [];

  let html = '';
  html += '<html><head><meta charset="UTF-8">';
  html += '<style>';
  html += 'body{font-family:Arial,sans-serif;font-size:12px;color:#111;}';
  html += 'h1{font-size:16px;margin-bottom:8px;}';
  html += 'h2{font-size:14px;margin-top:16px;margin-bottom:6px;}';
  html += 'table{width:100%;border-collapse:collapse;margin-bottom:10px;}';
  html += 'th,td{border:1px solid #ccc;padding:4px;text-align:left;}';
  html += '.small{font-size:11px;color:#333;}';
  html += '</style></head><body>';
  html += '<h1>Distribuição de Bolsas - Disciplinas por Departamento</h1>';

  dpts.forEach(function(dept) {
    html += '<h2>' + dept + '</h2>';
    html += '<table><thead><tr><th>Código</th><th>Disciplina</th><th>Professor</th><th>CT</th><th>CP</th><th>Peso</th></tr></thead><tbody>';
    const list = disciplines[dept] || [];
    if (!list.length) {
      html += '<tr><td colspan="6">Sem disciplinas</td></tr>';
    } else {
      list.forEach(function(d) {
        html += '<tr><td>' + esc_(d.codigo) + '</td><td>' + esc_(d.disciplina) + '</td><td>' + esc_(d.professor) + '</td><td>' + d.ct + '</td><td>' + d.cp + '</td><td>' + d.peso.toFixed(2) + '</td></tr>';
      });
    }
    html += '</tbody></table>';
  });

  html += '<h2>Melhores distribuições</h2>';
  if (!results.length) {
    html += '<p>Sem resultados.</p>';
  } else {
    html += '<table><thead><tr>';
    dpts.forEach(function(d) { html += '<th>' + d + '</th>'; });
    html += '<th>Desvio</th></tr></thead><tbody>';
    results.forEach(function(r) {
      html += '<tr>';
      dpts.forEach(function(d) { html += '<td>' + (r.allocByDept[d] || 0) + '</td>'; });
      html += '<td>' + r.sd.toFixed(4) + '</td>';
      html += '</tr>';
    });
    html += '</tbody></table>';
  }

  html += '<p class="small">Conforme deliberado em reunião da Comissão de Monitoria do CCA/UFSCar realizada em 24/02/2026 às 14h:</p>';
  html += '<ul class="small">';
  html += '<li>No cálculo das distribuições com menores desvios quadráticos foi atribuído o seguinte peso para cada disciplina: P = 1 + CP/(CT + CP), em que CT e CP são os números de créditos teóricos e de créditos práticos, respectivamente.</li>';
  html += '<li>Havendo menos bolsas do que solicitações, nenhuma das disciplinas aqui solicitadas deve ser optativa.</li>';
  html += '<li>O DRNPA concentra as suas duas bolsas - que todos os departamentos possuem direito por ano - apenas nos semestres ímpares, não fazendo solicitações nos semestres pares.</li>';
  html += '</ul>';

  html += '</body></html>';
  return html;
}

function esc_(text) {
  return String(text || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
