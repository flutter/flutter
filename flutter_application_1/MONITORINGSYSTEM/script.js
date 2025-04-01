let currentUser = null;

function login() {
    const badgeNumber = document.getElementById('badgeNumber').value.trim();
    if (!badgeNumber) {
        alert('Badge number is required. Please enter your badge number.');
        return;
    }

    currentUser = badgeNumber;
    toggleSections('login-section', 'monitoring-section');
    displayCurrentDate();
    createFootnote();
    alert(`Welcome, User ${badgeNumber}! You are now logged in.`);
    setupDropdownListeners();
}

function toggleSections(hideId, showId) {
    document.getElementById(hideId).style.display = 'none';
    document.getElementById(showId).style.display = 'block';
}

function displayCurrentDate() {
    const currentDate = new Date().toLocaleDateString();
    document.getElementById('date').innerText = `Date: ${currentDate}`;
}

function createFootnote() {
    const footnoteContainer = document.createElement('div');
    footnoteContainer.style.display = 'flex';
    footnoteContainer.style.justifyContent = 'space-between';
    footnoteContainer.style.marginTop = '20px';

    footnoteContainer.appendChild(createDropdown('Checked by', 'checkedBy', [
        "Melvie Del Mundo-Caoile",
        "Mary Antonette Erazo",
        "Saud Mohammed Sanchez",
        "Rahaf Fahad Al Othaimeen",
        "Muhannad Ahmed Ali",
        "Deema Ibrahim Al Humaidan"
    ]));

    footnoteContainer.appendChild(createDropdown('Reviewed by', 'reviewedBy', [
        "Shane Richel Esterban",
        "Haneen Saad Almanie"
    ], true));

    footnoteContainer.appendChild(createDropdown('Approved by', 'approvedBy', [
        "Dr. Eman A. Abouahmad"
    ], true));

    document.getElementById('monitoring-section').appendChild(footnoteContainer);
}

function createDropdown(labelText, id, options, includePlaceholder = false) {
    const container = document.createElement('div');
    container.style.textAlign = id === 'checkedBy' ? 'left' : id === 'reviewedBy' ? 'center' : 'right';

    const label = document.createElement('label');
    label.setAttribute('for', id);
    label.innerText = `${labelText}:`;

    const select = document.createElement('select');
    select.id = id;

    if (includePlaceholder) {
        const placeholder = document.createElement('option');
        placeholder.value = '';
        placeholder.innerText = 'Select Staff';
        select.appendChild(placeholder);
    }

    options.forEach(option => {
        const opt = document.createElement('option');
        opt.value = option;
        opt.innerText = option;
        select.appendChild(opt);
    });

    container.appendChild(label);
    container.appendChild(select);
    return container;
}

function viewData() {
    const savedData = JSON.parse(localStorage.getItem('monitoringData')) || [];
    const dataBody = document.getElementById('data-body');
    dataBody.innerHTML = '';

    if (savedData.length === 0) {
        alert('No saved data found.');
        return;
    }

    document.getElementById('saved-data-section').style.display = 'block';

    savedData.forEach(entry => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${entry.date}</td>
            <td>${entry.badgeNumber}</td>
            <td>${entry.benchtops ? 'Yes' : 'No'}</td>
            <td>${entry.keyboard ? 'Yes' : 'No'}</td>
            <td>${entry.mouse ? 'Yes' : 'No'}</td>
            <td>${entry.monitor ? 'Yes' : 'No'}</td>
            <td>${entry.phone ? 'Yes' : 'No'}</td>
        `;
        dataBody.appendChild(row);
    });
}

function saveAsPDF() {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();

    const savedData = JSON.parse(localStorage.getItem('monitoringData')) || [];
    if (savedData.length === 0) {
        alert('No saved data found to export.');
        return;
    }

    addPDFHeader(doc);
    addPDFTable(doc, savedData);
    addPDFFootnote(doc);

    doc.save('monitoring_data.pdf');
}

function addPDFHeader(doc) {
    doc.setFontSize(18);
    const title = 'MEDICAL AFFAIRS – LABORATORY SERVICES';
    doc.text(title, getCenteredX(doc, title), 20);

    doc.setFontSize(16);
    const subtitle = 'Surface Disinfection Monitoring';
    doc.text(subtitle, getCenteredX(doc, subtitle), 30);

    doc.setFontSize(12);
    doc.text('UNIT/LOCATION: MICROBIOLOGY', 14, 40);
    doc.text('MONTH/YEAR: APRIL 2025', 150, 40);
    doc.line(14, 45, 196, 45);
    doc.text('Saved Monitoring Data', 14, 50);
}

function addPDFTable(doc, data) {
    const headers = ['Date', 'Badge Number', 'Benchtops', 'Keyboard', 'Mouse', 'Monitor', 'Phone'];
    const tableData = data.map(entry => [
        entry.date,
        entry.badgeNumber,
        entry.benchtops ? 'Yes' : 'No',
        entry.keyboard ? 'Yes' : 'No',
        entry.mouse ? 'Yes' : 'No',
        entry.monitor ? 'Yes' : 'No',
        entry.phone ? 'Yes' : 'No'
    ]);

    let startY = 60;
    headers.forEach((header, index) => {
        doc.text(header, 14 + (index * 30), startY);
    });

    tableData.forEach((row, rowIndex) => {
        row.forEach((cell, cellIndex) => {
            doc.text(cell, 14 + (cellIndex * 30), startY + (rowIndex + 1) * 10);
        });
    });
}

function addPDFFootnote(doc) {
    const footnoteY = 60 + (JSON.parse(localStorage.getItem('monitoringData')).length + 2) * 10;
    doc.text('Checked by:', 14, footnoteY);
    doc.text(document.getElementById('checkedBy')?.value || 'N/A', 50, footnoteY);

    doc.text('Reviewed by:', 14, footnoteY + 10);
    doc.text(document.getElementById('reviewedBy')?.value || 'N/A', 50, footnoteY + 10);

    doc.text('Approved by:', 14, footnoteY + 20);
    doc.text(document.getElementById('approvedBy')?.value || 'N/A', 50, footnoteY + 20);
}

function getCenteredX(doc, text) {
    return (doc.internal.pageSize.getWidth() - doc.getTextWidth(text)) / 2;
}

function submitMonitoring() {
    if (!currentUser) {
        alert('Please log in first.');
        return;
    }

    const today = new Date().toISOString().split('T')[0];
    if (localStorage.getItem('lastSubmissionDate') === today) {
        alert('You have already submitted monitoring data for today.');
        return;
    }

    const monitoringData = {
        date: new Date().toLocaleDateString(),
        badgeNumber: currentUser,
        benchtops: document.getElementById('benchtops').checked,
        keyboard: document.getElementById('keyboard').checked,
        mouse: document.getElementById('mouse').checked,
        monitor: document.getElementById('monitor').checked,
        phone: document.getElementById('phone').checked,
    };

    const savedData = JSON.parse(localStorage.getItem('monitoringData')) || [];
    savedData.push(monitoringData);
    localStorage.setItem('monitoringData', JSON.stringify(savedData));
    localStorage.setItem('lastSubmissionDate', today);

    console.log('Monitoring Data:', monitoringData);
    alert('Monitoring data submitted successfully!');
}

function setupDropdownListeners() {
    const staffPositions = {
        "Melvie Del Mundo-Caoile": "Microbiology Section in-charge",
        "Mary Antonette Erazo": "Immunology Section in-charge",
        "Saud Mohammed Sanchez": "Blood Bank Section in-charge",
        "Rahaf Fahad Al Othaimeen": "Chemistry Section in-charge",
        "Muhannad Ahmed Ali": "Hematology/Clinical Microscopy Section in-charge",
        "Deema Ibrahim Al Humaidan": "Preanalytical Section in-charge",
        "Shane Richel Esterban": "Health and Safety Officer",
        "Haneen Saad Almanie": "Medical Technologist III",
        "Dr. Eman A. Abouahmad": "Laboratory Medical Director"
    };

    ['checkedBy', 'reviewedBy', 'approvedBy'].forEach(id => {
        const dropdown = document.getElementById(id);
        dropdown.addEventListener('change', () => {
            const position = staffPositions[dropdown.value] || 'N/A';
            alert(`Position: ${position}`);
        });
    });
}