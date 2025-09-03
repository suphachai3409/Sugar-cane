// plotRoutes.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// ใช้ db จาก mongoose
const db = mongoose.connection;

// POST /api/plots - สร้างแปลงปลูกใหม่
router.post('/', async (req, res) => {
  const { userId, ownerId, plotName, plantType, waterSource, soilType, latitude, longitude, polygonPoints } = req.body; // เพิ่ม ownerId

  try {
    const result = await db.collection('plots').insertOne({
      userId,
      ownerId, // เพิ่ม ownerId
      plotName,
      plantType,
      waterSource,
      soilType,
      latitude,
      longitude,
      polygonPoints: polygonPoints || [], // เพิ่มตรงนี้
      createdAt: new Date()
    });
    console.log('✅ kuy Plot saved:', {
      _id: result.insertedId,
      userId,
      ownerId,
      plotName,
      plantType,
      waterSource,
      soilType,
      latitude,
      longitude,
    });

    res.status(200).json({
      message: 'Plot saved successfully',
      plotId: result.insertedId
    });

  } catch (error) {
    console.error('❌ Error saving plot:', error);
    res.status(500).json({ error: 'Something went wrong' });
  }
});


// GET /api/plots/owner/:ownerId - ดึงแปลงปลูกของเจ้าของ
router.get('/owner/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  
  console.log('🔍 DEBUG: /api/plots/owner/:ownerId ถูกเรียก');
  console.log('🔍 DEBUG: ownerId จาก params:', ownerId);

  try {
    const query = { ownerId: ownerId };
    console.log('🔍 DEBUG: query ที่ใช้:', query);
    
    const plots = await db.collection('plots').find(query).sort({ createdAt: -1 }).toArray();
    console.log('🔍 DEBUG: plots ที่พบ:', plots);

    console.log(`✅ Found ${plots.length} plots for ownerId: ${ownerId}`);
    res.json(plots); // ส่งกลับเป็น array โดยตรง

  } catch (error) {
    console.error('❌ Error fetching plots by ownerId:', error);
    res.status(500).json({ message: 'Error fetching plots', error: error.message });
  }
});


// GET /api/plots/:userId - ดึงข้อมูลแปลงปลูกทั้งหมดของ user
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    // เปลี่ยนจาก ObjectId เป็น string เพื่อให้ตรงกับ frontend
    const plots = await db.collection('plots').find({
      userId: userId // ใช้ string ธรรมดา ไม่แปลงเป็น ObjectId
    }).sort({ createdAt: -1 }).toArray();

    console.log(`✅ Found ${plots.length} plots for userId: ${userId}`);
    res.json(plots); // ส่งกลับเป็น array โดยตรง (ไม่ต้องครอบด้วย object)

  } catch (error) {
    console.error('❌ Error fetching plots:', error);
    res.status(500).json({ message: 'Error fetching plots', error: error.message });
  }
});

// GET /api/plots/count/:userId - นับจำนวนแปลงปลูกของ user
router.get('/count/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    // เปลี่ยนจาก ObjectId เป็น string
    const count = await db.collection('plots').countDocuments({
      userId: userId // ใช้ string ธรรมดา
    });

    console.log(`✅ Plot count for userId ${userId}: ${count}`);
    res.json({ count });

  } catch (error) {
    console.error('❌ Error counting plots:', error);
    res.status(500).json({ message: 'Error counting plots', error: error.message });
  }
});

// DELETE /api/plots/:plotId - ลบแปลงปลูก (เผื่อต้องการใช้ในอนาคต)
router.delete('/:plotId', async (req, res) => {
  const { plotId } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const result = await db.collection('plots').deleteOne({
      _id: new mongoose.Types.ObjectId(plotId)
    });

    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    console.log(`✅ Deleted plot: ${plotId}`);
    res.json({ message: 'Plot deleted successfully' });

  } catch (error) {
    console.error('❌ Error deleting plot:', error);
    res.status(500).json({ message: 'Error deleting plot', error: error.message });
  }
});

// PUT /api/plots/:plotId - แก้ไขแปลงปลูก (เผื่อต้องการใช้ในอนาคต)
router.put('/:plotId', async (req, res) => {
  const { plotId } = req.params;
  const { plotName, plantType, waterSource, soilType, latitude, longitude, polygonPoints } = req.body; // เพิ่ม polygonPoints

  try {
    // ... (validate plotId)
    const result = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      {
        $set: {
          plotName,
          plantType,
          waterSource,
          soilType,
          latitude,
          longitude,
          polygonPoints: polygonPoints || [], // เพิ่มตรงนี้
          updatedAt: new Date()
        }
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    console.log(`✅ Updated plot: ${plotId}`);
    res.json({ message: 'Plot updated successfully' });

  } catch (error) {
    console.error('❌ Error updating plot:', error);
    res.status(500).json({ message: 'Error updating plot', error: error.message });
  }
});

// POST /api/plots/:plotId/recommendations - เพิ่ม recommendation
router.post('/:plotId/recommendations', async (req, res) => {
  const { plotId } = req.params;
  const { topic, date, message, images } = req.body;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const result = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      {
        $push: {
          recommendations: {
            topic,
            date,
            message,
            images: images || [],
            createdAt: new Date()
          }
        }
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    console.log(`✅ Added recommendation to plot: ${plotId}`);
    res.json({ message: 'Recommendation added successfully' });
  } catch (error) {
    console.error('❌ Error adding recommendation:', error);
    res.status(500).json({ message: 'Error adding recommendation', error: error.message });
  }
});

// GET /api/plots/:plotId/recommendations - ดึง recommendations ทั้งหมดของ plot
router.get('/:plotId/recommendations', async (req, res) => {
  const { plotId } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const plot = await db.collection('plots').findOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      { projection: { recommendations: 1 } }
    );

    if (!plot) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    res.json(plot.recommendations || []);
  } catch (error) {
    console.error('❌ Error fetching recommendations:', error);
    res.status(500).json({ message: 'Error fetching recommendations', error: error.message });
  }
});
// GET /api/plots/:plotId/recommendations/:topic
router.get('/:plotId/recommendations/:topic', async (req, res) => {
  const { plotId, topic } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const plot = await db.collection('plots').findOne(
      {
        _id: new mongoose.Types.ObjectId(plotId),
        'recommendations.topic': topic
      },
      {
        projection: {
          'recommendations.$': 1
        }
      }
    );

    if (!plot || !plot.recommendations || plot.recommendations.length === 0) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }

    res.json(plot.recommendations[0]);
  } catch (error) {
    console.error('❌ Error fetching recommendation:', error);
    res.status(500).json({ message: 'Error fetching recommendation', error: error.message });
  }
});

// PUT /api/plots/:plotId/recommendations/:topic
router.put('/:plotId/recommendations/:topic', async (req, res) => {
  const { plotId, topic } = req.params;
  const { date, message, images } = req.body;

  try {
    // Validate plotId
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    // Check if recommendation exists
    const existingRec = await db.collection('plots').findOne({
      _id: new mongoose.Types.ObjectId(plotId),
      'recommendations.topic': topic
    });

    if (!existingRec) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }

    // Update recommendation
    const result = await db.collection('plots').updateOne(
      { 
        _id: new mongoose.Types.ObjectId(plotId),
        'recommendations.topic': topic
      },
      { 
        $set: { 
          'recommendations.$.date': date,
          'recommendations.$.message': message,
          'recommendations.$.images': images || [],
          'recommendations.$.updatedAt': new Date()
        } 
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }

    res.json({ message: 'Recommendation updated successfully' });
  } catch (error) {
    console.error('❌ Error updating recommendation:', error);
    res.status(500).json({ message: 'Error updating recommendation', error: error.message });
  }
});

// DELETE /api/plots/:plotId/recommendations/:topic - ลบ recommendation โดยใช้ topic เป็น identifier
router.delete('/:plotId/recommendations/:topic', async (req, res) => {
  const { plotId, topic } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const result = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      {
        $pull: {
          recommendations: { topic: topic }
        }
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    console.log(`✅ Deleted recommendation from plot: ${plotId}, topic: ${topic}`);
    res.json({ message: 'Recommendation deleted successfully' });
  } catch (error) {
    console.error('❌ Error deleting recommendation:', error);
    res.status(500).json({ message: 'Error deleting recommendation', error: error.message });
  }
});
module.exports = router;
