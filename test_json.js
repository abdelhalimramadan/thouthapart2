const fs = require('fs');
['ar.json', 'en.json'].forEach(f => {
    try {
        JSON.parse(fs.readFileSync('c:/projects/thouthapart23/flutter_moblie_app/assets/translations/' + f, 'utf8'));
        console.log(f, 'is valid');
    } catch(e) {
        console.log(f, 'ERROR', e.message);
    }
});
